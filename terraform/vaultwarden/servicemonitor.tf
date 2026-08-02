resource "kubernetes_service" "vaultwarden_metrics" {
  metadata {
    name      = "vaultwarden-metrics"
    namespace = kubernetes_namespace.vaultwarden.metadata[0].name

    labels = {
      app = "vaultwarden"
    }
  }

  spec {
    selector = {
      app = "vaultwarden"
    }

    port {
      name        = "metrics"
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_manifest" "vaultwarden_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = "vaultwarden"
      namespace = kubernetes_namespace.vaultwarden.metadata[0].name
    }

    spec = {
      selector = {
        matchLabels = {
          app = "vaultwarden"
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
