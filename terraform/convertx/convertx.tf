locals {
  convertx_domain = "convertx.${var.server_base_domain}"
}

resource "kubernetes_config_map" "convertx_env" {
  metadata {
    name      = "convertx-env"
    namespace = kubernetes_namespace.convertx.metadata[0].name
  }

  data = {
    ALLOW_UNAUTHENTICATED        = "true"
    UNAUTHENTICATED_USER_SHARING = "true"
    HIDE_HISTORY                 = "true"
    HTTP_ALLOWED                 = "true"
  }
}

resource "kubernetes_deployment" "convertx" {
  metadata {
    name      = "convertx"
    namespace = kubernetes_namespace.convertx.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "convertx"
      }
    }

    template {
      metadata {
        labels = {
          app = "convertx"
        }
      }

      spec {
        container {
          image = "ghcr.io/c4illin/convertx:v0.18.0"
          name  = "convertx"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.convertx_env.metadata[0].name
            }
          }

          port {
            container_port = 3000
            name           = "http"
          }

          volume_mount {
            name       = "convertx-data"
            mount_path = "/app/data"
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 3000
            }

            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 3000
            }

            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          resources {
            requests = {
              cpu    = "500m"
              memory = "1Gi"
            }

            limits = {
              cpu    = "2"
              memory = "4Gi"
            }
          }
        }

        # Ephemeral working storage for uploads, converted outputs and the
        # SQLite DB. No PVC: history is disabled and the app runs in anonymous
        # mode, so nothing needs to survive a pod restart. Auto-delete
        # (AUTO_DELETE_EVERY_N_HOURS, default 24h) reclaims files during the
        # pod's lifetime.
        volume {
          name = "convertx-data"

          empty_dir {}
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.convertx_env,
    ]
  }
}

module "convertx_ingress" {
  source = "../modules/ingress"

  name      = "convertx"
  namespace = kubernetes_namespace.convertx.metadata[0].name
  domain    = local.convertx_domain

  target_port = 3000

  auth_mode = "oidc-interactive"

  selector = {
    app = "convertx"
  }
}
