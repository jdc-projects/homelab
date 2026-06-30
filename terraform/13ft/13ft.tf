resource "kubernetes_deployment" "_13ft" {
  metadata {
    name      = "13ft"
    namespace = kubernetes_namespace._13ft.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "13ft"
      }
    }

    template {
      metadata {
        labels = {
          app = "13ft"
        }
      }

      spec {
        container {
          image = "ghcr.io/wasi-master/13ft:0.4.0"
          name  = "13ft"

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
}

module "_13ft_ingress" {
  source = "../modules/ingress"

  name      = "a13ft"
  namespace = kubernetes_namespace._13ft.metadata[0].name
  domain    = "13ft.${var.server_base_domain}"

  target_port = 5000

  do_enable_keycloak_auth = true

  selector = {
    app = "13ft"
  }
}
