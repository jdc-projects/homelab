resource "kubernetes_manifest" "opensearch_operator_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = "opensearch-operator"
      namespace = kubernetes_namespace.opensearch_operator.metadata[0].name
    }

    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "opensearch-operator"
        }
      }

      endpoints = [
        {
          port            = "https"
          path            = "/metrics"
          scheme          = "https"
          tlsConfig       = { insecureSkipVerify = true }
          bearerTokenFile = "/var/run/secrets/kubernetes.io/serviceaccount/token"
        }
      ]
    }
  }
}
