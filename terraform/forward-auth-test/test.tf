resource "kubernetes_deployment" "traefik_forward_auth_test" {
  metadata {
    name      = "traefik-forward-auth-test"
    namespace = kubernetes_namespace.forward_auth_test.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "traefik-forward-auth-test"
      }
    }

    template {
      metadata {
        labels = {
          app = "traefik-forward-auth-test"
        }
      }

      spec {
        container {
          image = "node:20.9.0-bullseye"
          name  = "traefik-forward-auth-test"
        }
      }
    }
  }

  timeouts {
    create = "5m"
    update = "5m"
    delete = "5m"
  }
}

module "auth_ingress" {
  source = "../modules/auth-ingress"

  server_base_domain   = var.server_base_domain
  namespace            = kubernetes_namespace.forward_auth_test.metadata[0].name
  path_prefix          = "test"
  service_port         = "80"
  service_selector_app = kubernetes_deployment.traefik_forward_auth_test.spec[0].template[0].metadata[0].labels["app"]
}
