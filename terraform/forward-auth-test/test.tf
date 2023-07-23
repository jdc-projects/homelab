resource "kubernetes_deployment" "traefik_forward_auth_test" {
  metadata {
    name      = "traefik-forward-auth-test"
    namespace = kubernetes_namespace.oauth2_proxy.metadata[0].name
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
          image = "traefik/whoami:v1.10"
          name  = "traefik-forward-auth-test"
        }
      }
    }
  }

  timeouts {
    create = "1m"
    update = "1m"
    delete = "1m"
  }
}

module "auth-ingress" {
  source = "../modules/auth-ingress"

  server_base_domain = var.server_base_domain
  namespace = kubernetes_namespace.forward_auth_test.metadata[0].name
  path_prefix = "test2"
  service_selector_app = kubernetes_deployment.traefik_forward_auth_test.spec[0].template[0].metatdata[0].labels["app"]
}
