resource "kubernetes_service" "n8n_metrics" {
  metadata {
    name      = "n8n-metrics"
    namespace = kubernetes_namespace.n8n.metadata[0].name

    labels = {
      app = "n8n"
    }
  }

  spec {
    selector = {
      app = "n8n"
    }

    port {
      name        = "http"
      port        = 5678
      target_port = 5678
    }
  }
}

resource "kubernetes_manifest" "n8n_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = "n8n"
      namespace = kubernetes_namespace.n8n.metadata[0].name
    }

    spec = {
      selector = {
        matchLabels = {
          app = "n8n"
        }
      }

      endpoints = [
        {
          port = "http"
          path = "/metrics"
        }
      ]
    }
  }
}
