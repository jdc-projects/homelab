resource "kubernetes_config_map" "admin_env" {
  metadata {
    name      = "admin-env"
    namespace = kubernetes_namespace.appflowy.metadata[0].name
  }

  data = {
    RUST_LOG                  = "info"
    ADMIN_FRONTEND_REDIS_URL  = "" # *****
    ADMIN_FRONTEND_GOTRUE_URL = "" # *****
  }
}

resource "kubernetes_deployment" "admin" {
  metadata {
    name      = "admin"
    namespace = kubernetes_namespace.appflowy.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "admin"
      }
    }

    template {
      metadata {
        labels = {
          app = "admin"
        }
      }

      spec {
        container {
          image = "appflowyinc/admin_frontend:${local.appflowy_version}"
          name  = "admin"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.admin_env.metadata[0].name
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
      kubernetes_config_map.admin_env,
      kubernetes_secret.admin_env,
    ]
  }
}
