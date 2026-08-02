resource "kubernetes_manifest" "clickhouse_operator_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = "clickhouse-operator"
      namespace = kubernetes_namespace.clickhouse_operator.metadata[0].name
    }

    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "altinity-clickhouse-operator"
        }
      }

      endpoints = [
        {
          port = "op-metrics"
          path = "/metrics"
        },
        {
          port = "ch-metrics"
          path = "/metrics"
        }
      ]
    }
  }
}
