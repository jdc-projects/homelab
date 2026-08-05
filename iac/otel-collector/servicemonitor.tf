# ServiceMonitor for the collector's own self-telemetry (spans accepted/exported,
# queue depth, errors, memory) exposed on the operator-managed
# `otel-collector-monitoring` Service (:8888). The select-all Prometheus
# (iac/prometheus — `*SelectorNilUsesHelmValues=false`) picks this up with
# no selector labels required. This is distinct from application metrics - none
# flow yet; see collector.tf for why the prometheus exporter is not in use.
resource "kubernetes_manifest" "otel_collector_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = "otel-collector"
      namespace = local.namespace
    }

    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "otel-collector-monitoring"
        }
      }

      endpoints = [
        {
          port     = "monitoring"
          path     = "/metrics"
          interval = "30s"
        },
      ]
    }
  }

  depends_on = [kubernetes_manifest.otel_collector]
}
