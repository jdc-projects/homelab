resource "kuberentes_config_map" "blocky" {
  metadata {
    name = "blocky"
    namespace = kubernetes_namespace.blocky.metadata[0].name
  }

  data = {
    "config.yaml" = <<-EOF
      ports:
        https: 443
    EOF
  }
}

resource "kubernetes_deployment" "blocky" {
  metadata {
    name      = "blocky"
    namespace = kubernetes_namespace.blocky.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "blocky"
      }
    }

    template {
      metadata {
        labels = {
          app = "blocky"
        }
      }

      spec {
        container {
          image = "ghcr.io/0xerr0r/blocky:v0.24"
          name  = "blocky"

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }

            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }

            # ***** config mount
          }
        }
      }
    }
  }
}

module "blocky_ingress" {
  source = "../modules/ingress"

  name        = "blocky"
  namespace   = kubernetes_namespace.blocky.metadata[0].name
  domain      = "blocky.${var.server_base_domain}"
  target_port = 443
  selector = {
    app = "blocky"
  }

  do_enable_keycloak_auth = true
}
