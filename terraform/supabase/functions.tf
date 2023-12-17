resource "kubernetes_config_map" "functions_env" {
  metadata {
    name      = "functions-env"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    SUPABASE_URL = "http://kong"
    VERIFY_JWT   = "false"
  }
}

resource "kubernetes_secret" "functions_env" {
  metadata {
    name      = "functions-env"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    JWT_SECRET                = random_password.jwt_secret.result
    SUPABASE_ANON_KEY         = jwt_hashed_token.anon_key.token
    SUPABASE_SERVICE_ROLE_KEY = jwt_hashed_token.service_key.token
    SUPABASE_DB_URL           = "postgresql://postgres:${random_password.db_password.result}@${kubernetes_service.db.metadata[0].name}:${kubernetes_service.db.spec[0].port[0].port}/${kubernetes_config_map.db_env.data.PGDATABASE}"
  }
}

resource "kubernetes_deployment" "functions" {
  metadata {
    name      = "functions"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = "supabase"
        component = "functions"
      }
    }

    template {
      metadata {
        labels = {
          app       = "supabase"
          component = "functions"
        }
      }

      spec {
        container {
          image = "supabase/edge-runtime:v1.22.4"
          name  = "functions"

          command = ["start", "main-service", "/home/deno/functions/main"]

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
              name = kubernetes_config_map.functions_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.functions_env.metadata[0].name
            }
          }

          volume_mount {
            mount_path = "/home/deno/functions"
            name       = "functions-data"
          }
        }

        volume {
          name = "functions-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.supabase["functions"].metadata[0].name
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
    kubernetes_job.chown["functions"],
    kubernetes_deployment.analytics
  ]
}

resource "kubernetes_service" "functions" {
  metadata {
    name      = "functions"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    selector = {
      app       = "supabase"
      component = "functions"
    }

    port {
      port        = 80
      target_port = 0 # *****
    }
  }
}
