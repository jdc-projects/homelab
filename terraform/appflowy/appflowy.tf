resource "kubernetes_config_map" "appflowy_env" {
  metadata {
    name      = "appflowy-env"
    namespace = kubernetes_namespace.appflowy.metadata[0].name
  }

  data = {
    RUST_LOG                       = "info"
    APPFLOWY_ENVIRONMENT           = "production"
    APPFLOWY_REDIS_URI             = ""
    APPFLOWY_GOTRUE_JWT_EXP        = ""
    APPFLOWY_GOTRUE_BASE_URL       = ""
    APPFLOWY_GOTRUE_EXT_URL        = ""
    APPFLOWY_GOTRUE_ADMIN_EMAIL    = ""
    APPFLOWY_GOTRUE_ADMIN_PASSWORD = ""
    APPFLOWY_S3_USE_MINIO          = ""
    APPFLOWY_S3_MINIO_URL          = ""
    APPFLOWY_S3_ACCESS_KEY         = ""
    APPFLOWY_S3_SECRET_KEY         = ""
    APPFLOWY_S3_BUCKET             = ""
    APPFLOWY_S3_REGION             = ""
  }
}

resource "kubernetes_secret" "appflowy_env" {
  metadata {
    name      = "appflowy-env"
    namespace = kubernetes_namespace.appflowy.metadata[0].name
  }

  data = {
    APPFLOWY_DATABASE_URL      = ""
    APPFLOWY_GOTRUE_JWT_SECRET = ""
  }
}

resource "kubernetes_deployment" "appflowy" {
  metadata {
    name      = "appflowy"
    namespace = kubernetes_namespace.appflowy.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "appflowy"
      }
    }

    template {
      metadata {
        labels = {
          app = "appflowy"
        }
      }

      spec {
        container {
          image = "appflowyinc/appflowy_cloud:${local.appflowy_version}"
          name  = "appflowy"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.appflowy_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.appflowy_env.metadata[0].name
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
      kubernetes_config_map.appflowy_env,
      kubernetes_secret.appflowy_env,
    ]
  }
}
