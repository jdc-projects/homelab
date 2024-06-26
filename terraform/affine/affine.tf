locals {
  affine_server_host = "affine.${var.server_base_domain}"
}

resource "kubernetes_config_map" "affine_env" {
  metadata {
    name      = "affine-env"
    namespace = kubernetes_namespace.affine.metadata[0].name
  }

  data = {
    AFFINE_SERVER_HOST    = local.affine_server_host
    AFFINE_SERVER_PORT    = 3010
    AFFINE_SERVER_HTTPS   = "true"
    MAILER_HOST           = var.smtp_host
    MAILER_PORT           = var.smtp_port
    MAILER_USER           = var.smtp_username
    MAILER_SENDER         = "AFFiNE <noreply@${var.server_base_domain}>"
    REDIS_SERVER_HOST     = "${helm_release.redis.name}-master"
    REDIS_SERVER_PORT     = 6379
    REDIS_SERVER_USER     = ""
    REDIS_SERVER_DATABASE = 0
    NODE_OPTIONS          = "--import=./scripts/register.js"
    AFFINE_CONFIG_PATH    = "/root/.affine/config"
    NODE_ENV              = "production"
    # hack for signin URLs not being correct in emails
    NEXTAUTH_URL = "https://${local.affine_server_host}"
  }
}

resource "kubernetes_secret" "affine_env" {
  metadata {
    name      = "affine-env"
    namespace = kubernetes_namespace.affine.metadata[0].name
  }

  data = {
    MAILER_PASSWORD       = var.smtp_password
    DATABASE_URL          = "postgresql://${random_password.affine_db_username.result}:${random_password.affine_db_password.result}@${kubernetes_manifest.affine_db.manifest.metadata.name}-rw:5432/${kubernetes_manifest.affine_db.manifest.spec.bootstrap.initdb.database}"
    REDIS_SERVER_PASSWORD = random_password.affine_redis_password.result
    AFFINE_ADMIN_EMAIL    = "${random_password.affine_admin_username.result}@${var.server_base_domain}"
    AFFINE_ADMIN_PASSWORD = random_password.affine_admin_password.result
  }
}

resource "kubernetes_deployment" "affine" {
  metadata {
    name      = "affine"
    namespace = kubernetes_namespace.affine.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "affine"
      }
    }

    template {
      metadata {
        labels = {
          app = "affine"
        }
      }

      spec {
        container {
          image = "ghcr.io/toeverything/affine-graphql:stable-cd56d8a"
          name  = "affine"

          command = ["sh", "-c", "node ./scripts/self-host-predeploy && node ./dist/index.js"]

          env_from {
            config_map_ref {
              name = kubernetes_config_map.affine_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.affine_env.metadata[0].name
            }
          }

          volume_mount {
            mount_path = "/root/.affine/config"
            name       = "affine-config"
          }

          volume_mount {
            mount_path = "/root/.affine/storage"
            name       = "affine-storage"
          }

          resources {
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }

            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }

        volume {
          name = "affine-config"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.affine["config"].metadata[0].name
          }
        }

        volume {
          name = "affine-storage"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.affine["storage"].metadata[0].name
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.affine_env,
      kubernetes_secret.affine_env,
    ]
  }
}
