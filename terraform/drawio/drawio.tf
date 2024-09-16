locals {
  drawio_domain = "draw.${var.server_base_domain}"
}

resource "kubernetes_config_map" "drawio_env" {
  metadata {
    name      = "drawio-env"
    namespace = kubernetes_namespace.drawio.metadata[0].name
  }

  data = {
    DRAWIO_SERVER_URL   = "https://${local.drawio_domain}"
    DRAWIO_VIEWER_URL   = "https://${local.drawio_domain}/js/viewer.min.js"
    DRAWIO_LIGHTBOX_URL = "https://${local.drawio_domain}"
  }
}

resource "kubernetes_deployment" "drawio" {
  metadata {
    name      = "drawio"
    namespace = kubernetes_namespace.drawio.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "drawio"
      }
    }

    template {
      metadata {
        labels = {
          app = "drawio"
        }
      }

      spec {
        container {
          image = "jgraph/drawio:24.4.15"
          name  = "drawio"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.drawio_env.metadata[0].name
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
      kubernetes_config_map.drawio_env,
    ]
  }
}

module "drawio_ingress" {
  source = "../modules/ingress"

  name      = "drawio"
  namespace = kubernetes_namespace.drawio.metadata[0].name
  domain    = local.drawio_domain

  target_port = 8080

  selector = {
    app = "drawio"
  }

  do_enable_keycloak_auth = true
}
