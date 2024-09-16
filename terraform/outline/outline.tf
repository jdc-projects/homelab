locals {
  outline_domain = "notes.${var.server_base_domain}"
}

resource "kubernetes_config_map" "outline_env" {
  metadata {
    name      = "outline-env"
    namespace = kubernetes_namespace.outline.metadata[0].name
  }

  data = {
    NODE_ENV                     = "production"
    URL                          = "https://${local.outline_domain}"
    PORT                         = 3000
    AWS_ACCESS_KEY_ID            = random_password.minio_access_key.result
    AWS_REGION                   = "us-east-1"
    AWS_S3_UPLOAD_BUCKET_URL     = "https://${local.minio_domain}/${local.minio_bucket_name}"
    AWS_S3_ACCELERATE_URL        = "https://${local.minio_domain}/${local.minio_bucket_name}"
    AWS_S3_UPLOAD_BUCKET_NAME    = local.minio_bucket_name
    AWS_S3_FORCE_PATH_STYLE      = "true"
    FILE_STORAGE                 = "s3"
    FILE_STORAGE_LOCAL_ROOT_DIR  = "/var/lib/outline/data" # shouldn't be needed since we're using S3 (minio), but set it just in case
    FILE_STORAGE_UPLOAD_MAX_SIZE = 1000000000              # 1G
    OIDC_CLIENT_ID               = keycloak_openid_client.outline.client_id
    OIDC_AUTH_URI                = data.terraform_remote_state.keycloak.outputs.keycloak_auth_url
    OIDC_TOKEN_URI               = data.terraform_remote_state.keycloak.outputs.keycloak_token_url
    OIDC_USERINFO_URI            = data.terraform_remote_state.keycloak.outputs.keycloak_api_url
    OIDC_LOGOUT_URI              = data.terraform_remote_state.keycloak.outputs.keycloak_logout_url
    OIDC_USERNAME_CLAIM          = "preferred_username"
    OIDC_DISPLAY_NAME            = "Keycloak"
    OIDC_SCOPES                  = "openid"
    FORCE_HTTPS                  = "false" # handled by Traefik
    TELEMETRY                    = "false"
    ENABLE_UPDATES               = "false" # this is actually a telemetry flag...
    WEB_CONCURRENCY              = 1       # memory in M / 512 (ish)
    DEBUG                        = ""
    LOG_LEVEL                    = "info"
    SMTP_HOST                    = var.smtp_host
    SMTP_PORT                    = var.smtp_port
    SMTP_USERNAME                = var.smtp_username
    SMTP_FROM_EMAIL              = "Outline <noreply@${var.server_base_domain}>"
    SMTP_REPLY_EMAIL             = ""
    SMTP_TLS_CIPHERS             = ""
    SMTP_SECURE                  = "true"
    DEFAULT_LANGUAGE             = "en_US"
    RATE_LIMITER_ENABLED         = "true"
    RATE_LIMITER_REQUESTS        = 1000
    RATE_LIMITER_DURATION_WINDOW = 60
  }
}

resource "kubernetes_secret" "outline_env" {
  metadata {
    name      = "outline-env"
    namespace = kubernetes_namespace.outline.metadata[0].name
  }

  data = {
    SECRET_KEY            = random_id.outline_secret_key.hex
    UTILS_SECRET          = random_id.outline_utils_secret.hex
    DATABASE_URL          = "postgresql://${random_password.outline_db_username.result}:${random_password.outline_db_password.result}@${kubernetes_manifest.outline_db.manifest.metadata.name}-rw:5432/${kubernetes_manifest.outline_db.manifest.spec.bootstrap.initdb.database}"
    REDIS_URL             = "redis://:${random_password.outline_redis_password.result}@${helm_release.redis.name}-master:6379"
    AWS_SECRET_ACCESS_KEY = random_password.minio_secret_key.result
    OIDC_CLIENT_SECRET    = random_password.keycloak_client_secret.result
    SMTP_PASSWORD         = var.smtp_password
  }
}

resource "kubernetes_deployment" "outline" {
  metadata {
    name      = "outline"
    namespace = kubernetes_namespace.outline.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "outline"
      }
    }

    template {
      metadata {
        labels = {
          app = "outline"
        }
      }

      spec {
        container {
          image = "outlinewiki/outline:0.76.1"
          name  = "outline"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.outline_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.outline_env.metadata[0].name
            }
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
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.outline_env,
      kubernetes_secret.outline_env,
    ]
  }
}
