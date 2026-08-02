resource "kubernetes_service" "personhog_replica_metrics" {
  metadata {
    name      = "personhog-replica-metrics"
    namespace = kubernetes_namespace.posthog.metadata[0].name

    labels = {
      app = "personhog-replica"
    }
  }

  spec {
    selector = {
      app = "personhog-replica"
    }

    port {
      name        = "metrics"
      port        = 9100
      target_port = 9100
    }
  }
}

resource "kubernetes_manifest" "personhog_replica_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = "personhog-replica"
      namespace = kubernetes_namespace.posthog.metadata[0].name
    }

    spec = {
      selector = {
        matchLabels = {
          app = "personhog-replica"
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

resource "kubernetes_service" "personhog_router_metrics" {
  metadata {
    name      = "personhog-router-metrics"
    namespace = kubernetes_namespace.posthog.metadata[0].name

    labels = {
      app = "personhog-router"
    }
  }

  spec {
    selector = {
      app = "personhog-router"
    }

    port {
      name        = "metrics"
      port        = 9101
      target_port = 9101
    }
  }
}

resource "kubernetes_manifest" "personhog_router_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = "personhog-router"
      namespace = kubernetes_namespace.posthog.metadata[0].name
    }

    spec = {
      selector = {
        matchLabels = {
          app = "personhog-router"
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
