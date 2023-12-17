resource "kubernetes_config_map" "analytics_env" {
  metadata {
    name      = "analytics-env"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    LOGFLARE_NODE_HOST             = "127.0.0.1"
    DB_USERNAME                    = "supabase_admin"
    DB_DATABASE                    = kubernetes_config_map.db_env.data.PGDATABASE
    DB_HOSTNAME                    = kubernetes_service.db.metadata[0].name
    DB_PORT                        = kubernetes_config_map.db_env.data.PGPORT
    DB_SCHEMA                      = "_analytics"
    LOGFLARE_SINGLE_TENANT         = "true"
    LOGFLARE_SUPABASE_MODE         = "true"
    LOGFLARE_MIN_CLUSTER_SIZE      = "1"
    RELEASE_COOKIE                 = "cookie"
    POSTGRES_BACKEND_SCHEMA        = "_analytics"
    LOGFLARE_FEATURE_FLAG_OVERRIDE = "multibackend=true"
    # GOOGLE_PROJECT_ID = "local.GOOGLE_PROJECT_ID"
    # GOOGLE_PROJECT_NUMBER = "local.GOOGLE_PROJECT_NUMBER"
  }
}

resource "kubernetes_secret" "analytics_env" {
  metadata {
    name      = "analytics-env"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    DB_PASSWORD          = random_password.db_password.result
    LOGFLARE_API_KEY     = random_password.logflare_api_key.result
    POSTGRES_BACKEND_URL = "postgresql://supabase_admin:${random_password.db_password.result}@${kubernetes_service.db.metadata[0].name}:${kubernetes_service.db.spec[0].port[0].port}/${kubernetes_config_map.db_env.data.PGDATABASE}"
  }
}

resource "kubernetes_deployment" "analytics" {
  metadata {
    name      = "analytics"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = "supabase"
        component = "analytics"
      }
    }

    template {
      metadata {
        labels = {
          app       = "supabase"
          component = "analytics"
        }
      }

      spec {
        container {
          image = "supabase/logflare:1.4.0"
          name  = "analytics"

          command = [
            "sh -c",
            "run.sh && sh run.sh",
            "./logflare eval Logflare.Release.migrate",
            "./logflare start --sname logflare"
          ]

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
              name = kubernetes_config_map.analytics_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.analytics_env.metadata[0].name
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
}

resource "kubernetes_service" "analytics" {
  metadata {
    name      = "analytics"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    selector = {
      app       = "supabase"
      component = "analytics"
    }

    port {
      port        = 80
      target_port = 4000
    }
  }
}
