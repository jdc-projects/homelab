resource "kubernetes_deployment" "browserless" {
  metadata {
    name      = "browserless"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "browserless" }
    }

    template {
      metadata {
        labels = { app = "browserless" }
      }

      spec {
        container {
          image = local.browserless_image
          name  = "browserless"

          env_from {
            secret_ref { name = kubernetes_secret.browserless_secrets.metadata[0].name }
          }

          port { container_port = 3000 }

          resources {
            requests = { cpu = "200m", memory = "512Mi" }
            limits   = { cpu = "500m", memory = "1Gi" }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "browserless" {
  metadata {
    name      = "browserless"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  spec {
    selector = { app = "browserless" }
    port {
      port        = 3000
      target_port = 3000
    }
  }
}
