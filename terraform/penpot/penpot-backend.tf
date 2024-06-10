resource "kubernetes_config_map" "penpot_backend_env" {
  metadata {
    name      = "penpot-backend-env"
    namespace = kubernetes_namespace.penpot.metadata[0].name
  }

  data = {
    PENPOT_FLAGS          = local.penpot_shared_flags
    PENPOT_OIDC_CLIENT_ID = keycloak_openid_client.penpot.client_id
    PENPOT_OIDC_BASE_URI  = "${data.terraform_remote_state.keycloak_config.outputs.keycloak_url}/realms/${data.terraform_remote_state.keycloak_config.outputs.primary_realm_id}/protocol/openid-connect"
    # PENPOT_OIDC_ROLES      = ""
    # PENPOT_OIDC_ROLES_ATTR = "roles"
    PENPOT_OIDC_SCOPES                 = "openid"
    PENPOT_OIDC_NAME_ATTR              = "name"
    PENPOT_OIDC_EMAIL_ATTR             = "email"
    PENPOT_DATABASE_URI                = "postgresql://${kubernetes_manifest.penpot_db.manifest.metadata.name}-rw:5432/${kubernetes_manifest.penpot_db.manifest.spec.bootstrap.initdb.database}"
    PENPOT_SMTP_DEFAULT_REPLY_TO       = ""
    PENPOT_SMTP_DEFAULT_FROM           = "Penpot <noreply@${var.server_base_domain}>"
    PENPOT_SMTP_HOST                   = var.smtp_host
    PENPOT_SMTP_PORT                   = var.smtp_port
    PENPOT_SMTP_USERNAME               = var.smtp_username
    PENPOT_SMTP_TLS                    = "true"
    PENPOT_ASSETS_STORAGE_BACKEND      = "assets-s3"
    PENPOT_STORAGE_ASSETS_FS_DIRECTORY = "/opt/data/assets" # shouldn't be needed with the s3 backend
    AWS_ACCESS_KEY_ID                  = random_password.minio_access_key.result
    PENPOT_STORAGE_ASSETS_S3_REGION    = "us-east-1"
    PENPOT_STORAGE_ASSETS_S3_BUCKET    = local.minio_bucket_name
    PENPOT_STORAGE_ASSETS_S3_ENDPOINT  = "http://${helm_release.minio.name}:9000"
    PENPOT_HTTP_SERVER_PORT            = 6060
    PENPOT_HTTP_SERVER_HOST            = "penpot-backend"
    PENPOT_PUBLIC_URI                  = "https://${local.penpot_domain}"
  }
}

resource "kubernetes_secret" "penpot_backend_env" {
  metadata {
    name      = "penpot-backend-env"
    namespace = kubernetes_namespace.penpot.metadata[0].name
  }

  data = {
    PENPOT_OIDC_CLIENT_SECRET = random_password.keycloak_client_secret.result
    PENPOT_DATABASE_USERNAME  = random_password.penpot_db_username.result
    PENPOT_DATABASE_PASSWORD  = random_password.penpot_db_password.result
    PENPOT_SMTP_PASSWORD      = var.smtp_password
    AWS_SECRET_ACCESS_KEY     = random_password.minio_secret_key.result
    PENPOT_REDIS_URI          = "redis://:${random_password.penpot_redis_password.result}@${helm_release.redis.name}-master:6379"
  }
}

resource "kubernetes_deployment" "penpot_backend" {
  metadata {
    name      = "penpot-backend"
    namespace = kubernetes_namespace.penpot.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "penpot-backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "penpot-backend"
        }
      }

      spec {
        container {
          image = "penpotapp/backend:${local.penpot_version}"
          name  = "penpot-backend"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.penpot_backend_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.penpot_backend_env.metadata[0].name
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
      kubernetes_config_map.penpot_backend_env,
      kubernetes_secret.penpot_backend_env,
    ]
  }
}
