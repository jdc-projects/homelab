resource "kubernetes_config_map" "studio_env" {
  metadata {
    name      = "studio-env"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    STUDIO_PG_META_URL              = "http://meta"
    DEFAULT_ORGANIZATION_NAME       = local.STUDIO_DEFAULT_ORGANIZATION
    DEFAULT_PROJECT_NAME            = local.STUDIO_DEFAULT_PROJECT
    SUPABASE_URL                    = "http://kong"
    SUPABASE_PUBLIC_URL             = local.SUPABASE_PUBLIC_URL
    LOGFLARE_URL                    = "http://analytics"
    NEXT_PUBLIC_ENABLE_LOGS         = "true"
    NEXT_ANALYTICS_BACKEND_PROVIDER = "postgres"
  }
}

resource "kubernetes_secret" "studio_env" {
  metadata {
    name      = "studio-env"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    POSTGRES_PASSWORD    = random_password.db_password.result
    SUPABASE_ANON_KEY    = jwt_hashed_token.anon_key.token
    SUPABASE_SERVICE_KEY = jwt_hashed_token.service_key.token
    LOGFLARE_API_KEY     = random_password.logflare_api_key.result
  }
}

resource "kubernetes_deployment" "studio" {
  metadata {
    name      = "studio"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = "supabase"
        component = "studio"
      }
    }

    template {
      metadata {
        labels = {
          app       = "supabase"
          component = "studio"
        }
      }

      spec {
        container {
          image = "supabase/studio:20231123-64a766a"
          name  = "studio"

          liveness_probe {
            http_get {
              path = "/api/profile"
              port = 3000
            }

            initial_delay_seconds = 5
            period_seconds        = 5
            failure_threshold     = 3
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }

            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.studio_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.studio_env.metadata[0].name
            }
          }
        }
      }
    }
  }

  timeouts {
    create = "5m"
    update = "5m"
    delete = "5m"
  }

  depends_on = [
    kubernetes_deployment.meta
  ]
}

resource "kubernetes_service" "studio" {
  metadata {
    name      = "studio"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    selector = {
      app       = "supabase"
      component = "studio"
    }

    port {
      port        = 80
      target_port = kubernetes_deployment.studio.spec[0].template[0].spec[0].container[0].liveness_probe[0].http_get[0].port
    }
  }
}
