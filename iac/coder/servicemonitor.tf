# Coderd exposes Prometheus metrics on :2112 (CODER_PROMETHEUS_ENABLE), which
# the chart's Service does not expose - hence a dedicated metrics Service.

resource "kubernetes_service" "coder_metrics" {
  metadata {
    name      = "coder-metrics"
    namespace = kubernetes_namespace.coder.metadata[0].name

    labels = {
      app = "coder-metrics"
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name"     = "coder"
      "app.kubernetes.io/instance" = "coder"
    }

    port {
      name        = "metrics"
      port        = 2112
      target_port = 2112
    }
  }
}

resource "kubernetes_manifest" "coder_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = "coder"
      namespace = kubernetes_namespace.coder.metadata[0].name
    }

    spec = {
      selector = {
        matchLabels = {
          app = "coder-metrics"
        }
      }

      endpoints = [
        {
          port = "metrics"
          path = "/metrics"
        }
      ]
    }
  }
}
