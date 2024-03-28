resource "kubernetes_config_map" "postgres_debug_env" {
  metadata {
    name      = "postgres-debug-env"
    namespace = kubernetes_namespace.grist.metadata[0].name
  }

  data = {
  }
}

resource "kubernetes_secret" "postgres_debug_env" {
  metadata {
    name      = "postgres-debug-env"
    namespace = kubernetes_namespace.grist.metadata[0].name
  }

  data = {
    POSTGRES_PASSWORD = random_password.grist_db_password.result
    POSTGRES_USER = random_password.grist_db_username.result
    POSTGRES_DB = kubernetes_manifest.grist_db.manifest.spec.bootstrap.initdb.database
  }
}

resource "kubernetes_deployment" "postgres_debug" {
  metadata {
    name      = "postgres-debug"
    namespace = kubernetes_namespace.grist.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postgres-debug"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres-debug"
        }
      }

      spec {
        container {
          image = "postgres:16.2-alpine3.19"
          name  = "postgres-debug"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.postgres_debug_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.postgres_debug_env.metadata[0].name
            }
          }

          # volume_mount {
          #   mount_path = "/var/lib/postgresql/data"
          #   name       = "postgres-debug-data"
          # }

          # resources {
          #   requests = {
          #     cpu    = "500m"
          #     memory = "512Mi"
          #   }

          #   limits = {
          #     cpu    = "1"
          #     memory = "1Gi"
          #   }
          # }
        }

        # volume {
        #   name = "postgres-debug-data"

        #   persistent_volume_claim {
        #     claim_name = kubernetes_persistent_volume_claim.postgres_debug.metadata[0].name
        #   }
        # }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.postgres_debug_env,
      kubernetes_secret.postgres_debug_env,
    ]
  }
}

resource "kubernetes_service" "postgres_debug" {
  metadata {
    name      = "postgres-debug"
    namespace = kubernetes_namespace.grist.metadata[0].name
  }

  spec {
    selector = {
      app = "postgres-debug"
    }

    port {
      port        = 5432
      target_port = 5432
    }
  }
}
