# Grafana datasource for Tempo. Lives in the tempo namespace (the data owner)
# and is imported cross-namespace into the Grafana instance via
# allowCrossNamespaceImport + instanceSelector, mirroring the pattern used by
# the Prometheus datasource in terraform/prometheus/grafana-datasource.tf.
#
# tracesToLogs wires Tempo traces to the existing Loki datasource: clicking a
# span jumps to the matching Loki log lines filtered by traceId (emitted into
# Loki structured metadata by the promtail pipeline stage added in
# terraform/grafana/promtail.tf).  The Loki datasource UID is grafana-operator
# generated (a UUID, not name-derived) — it is read here as a local so the
# coupling is explicit.

locals {
  # Grafana-assigned UID of the "Loki" datasource. Verified via the Grafana API.
  loki_datasource_uid = "c109d3a5-4c71-4d7d-9f1e-df22853d6af3"
}

resource "kubernetes_manifest" "tempo_grafana_datasource" {
  manifest = {
    apiVersion = "grafana.integreatly.org/v1beta1"
    kind       = "GrafanaDatasource"

    metadata = {
      name      = "tempo"
      namespace = kubernetes_namespace.tempo.metadata[0].name
    }

    spec = {
      allowCrossNamespaceImport = "true"

      instanceSelector = {
        matchLabels = data.terraform_remote_state.grafana.outputs.grafana_deployment_labels
      }

      datasource = {
        name = "Tempo"
        type = "tempo"

        access = "proxy"

        url = "http://tempo-query-frontend.${kubernetes_namespace.tempo.metadata[0].name}.svc.cluster.local:3200"

        jsonData = {
          tracesToLogs = {
            datasourceUid   = local.loki_datasource_uid
            filterByTraceID = true
            # Span attributes that map to Loki stream labels emitted by promtail.
            # The collector (terraform/otel-collector/) adds matching `namespace`
            # and `pod` resource attributes via its k8sattributes processor.
            tags = ["namespace", "pod"]
          }
        }
      }
    }
  }

  depends_on = [helm_release.tempo]
}
