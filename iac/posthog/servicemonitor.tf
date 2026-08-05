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

resource "kubernetes_manifest" "kafka_podmonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PodMonitor"

    metadata = {
      name      = "kafka"
      namespace = kubernetes_namespace.posthog.metadata[0].name
    }

    spec = {
      selector = {
        matchLabels = {
          "strimzi.io/cluster" = "kafka"
          "strimzi.io/kind"    = "Kafka"
        }
      }

      podMetricsEndpoints = [
        {
          port = "tcp-prometheus"
          path = "/metrics"
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "clickhouse_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = "clickhouse"
      namespace = kubernetes_namespace.posthog.metadata[0].name
    }

    spec = {
      selector = {
        matchLabels = {
          "clickhouse.altinity.com/chi" = "posthog-ch"
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

# ---------------------------------------------------------------------------
# Temporal metrics (PROMETHEUS_ENDPOINT=0.0.0.0:8001 served by temporal-server)
# ---------------------------------------------------------------------------
resource "kubernetes_manifest" "temporal_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = "temporal"
      namespace = kubernetes_namespace.posthog.metadata[0].name
    }

    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "temporal"
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

# ---------------------------------------------------------------------------
# OpenSearch prometheus-exporter plugin (/_prometheus/metrics on :9200)
# The opensearch-operator creates an `opensearch` service (and a headless
# `opensearch-nodes` service) labelled `opensearch.org/opensearch-cluster`.
# The prometheus-exporter plugin (installed via spec.general.pluginsList) serves
# /_prometheus/metrics on the standard HTTP port (9200, port name "http").
# ---------------------------------------------------------------------------
resource "kubernetes_manifest" "opensearch_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = "opensearch"
      namespace = kubernetes_namespace.posthog.metadata[0].name
    }

    spec = {
      selector = {
        matchLabels = {
          "opensearch.org/opensearch-cluster" = "opensearch"
        }
      }

      endpoints = [
        {
          port = "http"
          path = "/_prometheus/metrics"
        }
      ]
    }
  }
}
