resource "kubernetes_namespace" "whoami" {
  metadata {
    name = "whoami"
  }
}

resource "kubernetes_deployment" "whoami" {
  metadata {
    name      = "whoami"
    namespace = kubernetes_namespace.whoami.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "whoami"
      }
    }

    template {
      metadata {
        labels = {
          app = "whoami"
        }
      }

      spec {
        container {
          image = "traefik/whoami:v1.10"
          name  = "whoami"

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
        }
      }
    }
  }
}

module "whoami_ingress" {
  source = "../modules/ingress"

  name        = "whoami"
  namespace   = kubernetes_namespace.whoami.metadata[0].name
  domain      = "whoami.${var.server_base_domain}"
  target_port = 80
  selector = {
    app = "whoami"
  }

  do_enable_keycloak_auth = true
}
