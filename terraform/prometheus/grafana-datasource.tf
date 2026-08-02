# Grafana datasource for Prometheus. Lives in the prometheus namespace (the
# data owner) and is imported cross-namespace into the Grafana instance via
# allowCrossNamespaceImport + instanceSelector. Mirrors the pattern used by
# the Loki datasource in terraform/grafana/grafana-datasource.tf.

resource "kubernetes_manifest" "prometheus_grafana_datasource" {
  manifest = {
    apiVersion = "grafana.integreatly.org/v1beta1"
    kind       = "GrafanaDatasource"

    metadata = {
      name      = "prometheus"
      namespace = kubernetes_namespace.prometheus.metadata[0].name
    }

    spec = {
      allowCrossNamespaceImport = "true"

      instanceSelector = {
        matchLabels = data.terraform_remote_state.grafana.outputs.grafana_deployment_labels
      }

      datasource = {
        name = "Prometheus"
        type = "prometheus"

        access = "proxy"

        url = "http://${helm_release.kube_prometheus_stack.name}-prometheus.${kubernetes_namespace.prometheus.metadata[0].name}.svc.cluster.local:9090"

        isDefault = "true"
      }
    }
  }

  depends_on = [helm_release.kube_prometheus_stack]
}
