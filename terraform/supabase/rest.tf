resource "kubernetes_config_map" "rest_env" {
  metadata {
    name      = "rest-env"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    PGRST_DB_SCHEMAS           = "public,storage,graphql_public"
    PGRST_DB_ANON_ROLE         = "anon"
    PGRST_DB_USE_LEGACY_GUCS   = "false"
    PGRST_APP_SETTINGS_JWT_EXP = local.JWT_EXPIRY
  }
}

resource "kubernetes_secret" "rest_env" {
  metadata {
    name      = "rest-env"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    PGRST_DB_URI                  = "postgres://authenticator:${random_password.db_password.result}@${kubernetes_service.db.metadata[0].name}:${kubernetes_service.db.spec[0].port[0].port}/${kubernetes_config_map.db_env.data.PGDATABASE}"
    PGRST_JWT_SECRET              = random_password.jwt_secret.result
    PGRST_APP_SETTINGS_JWT_SECRET = random_password.jwt_secret.result
  }
}

resource "kubernetes_deployment" "rest" {
  metadata {
    name      = "rest"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = "supabase"
        component = "rest"
      }
    }

    template {
      metadata {
        labels = {
          app       = "supabase"
          component = "rest"
        }
      }

      spec {
        container {
          image = "postgrest/postgrest:v11.2.2"
          name  = "rest"

          command = ["postgrest"]

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
              name = kubernetes_config_map.rest_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.rest_env.metadata[0].name
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
    kubernetes_deployment.db,
    kubernetes_deployment.analytics
  ]
}

resource "kubernetes_service" "rest" {
  metadata {
    name      = "rest"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    selector = {
      app       = "supabase"
      component = "rest"
    }

    port {
      port        = 80
      target_port = 0 # *****
    }
  }
}
