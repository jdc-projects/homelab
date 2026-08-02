# NOTE: This ServiceMonitor is currently non-functional. The opensearch-operator
# chart (v2.8.4) hardcodes `--metrics-bind-address=127.0.0.1:8080` (localhost
# only), so Prometheus cannot reach the metrics endpoint externally. The target
# will show as "down" with "connection refused" until the chart exposes metrics
# on 0.0.0.0. Track: https://github.com/opensearch-project/opensearch-k8s-operator
# — check if a newer chart version adds a `manager.metrics.bindAddress` value (or
# similar) that can be overridden. Once fixed, also add port 8080 to the
# opensearch-operator Service (currently only exposes 8443) and update the
# endpoint below to target port 8080 (HTTP, not HTTPS).
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
