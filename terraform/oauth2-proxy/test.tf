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
