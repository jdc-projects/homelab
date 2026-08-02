resource "kubernetes_service" "strimzi_operator_metrics" {
  metadata {
    name      = "strimzi-operator-metrics"
    namespace = kubernetes_namespace.kafka_operator.metadata[0].name

    labels = {
      "app.kubernetes.io/name" = "strimzi-operator"
    }
  }

  spec {
    selector = {
      name              = "strimzi-cluster-operator"
      "strimzi.io/kind" = "cluster-operator"
    }

    port {
      name        = "http"
      port        = 8080
      target_port = "http"
    }
  }
}

resource "kubernetes_manifest" "strimzi_operator_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = "strimzi-operator"
      namespace = kubernetes_namespace.kafka_operator.metadata[0].name
    }

    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "strimzi-operator"
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
