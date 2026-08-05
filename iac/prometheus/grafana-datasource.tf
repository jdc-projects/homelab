# Grafana datasource for Prometheus. Lives in the prometheus namespace (the
# data owner) and is imported cross-namespace into the Grafana instance via
# allowCrossNamespaceImport + instanceSelector. Mirrors the pattern used by
# the Loki datasource in iac/grafana/grafana-datasource.tf.

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

# Grafana datasource for the kube-prometheus-stack Alertmanager. External
# Alertmanagers must be wired into Grafana as a datasource; the legacy
# [unified_alerting] alertmanager_url key no longer registers one. This lets
# the Alerting UI (Active notifications / alert groups, silences) read from the
# Prometheus Alertmanager where alerts actually fire. Same cross-namespace
# import pattern as the Prometheus datasource above.

resource "kubernetes_manifest" "alertmanager_grafana_datasource" {
  manifest = {
    apiVersion = "grafana.integreatly.org/v1beta1"
    kind       = "GrafanaDatasource"

    metadata = {
      name      = "alertmanager"
      namespace = kubernetes_namespace.prometheus.metadata[0].name
    }

    spec = {
      allowCrossNamespaceImport = "true"

      instanceSelector = {
        matchLabels = data.terraform_remote_state.grafana.outputs.grafana_deployment_labels
      }

      datasource = {
        name = "Prometheus Alertmanager"
        type = "alertmanager"

        access = "proxy"

        url = "http://${helm_release.kube_prometheus_stack.name}-alertmanager.${kubernetes_namespace.prometheus.metadata[0].name}.svc.cluster.local:9093"

        jsonData = {
          implementation = "prometheus"
        }
      }
    }
  }

  depends_on = [helm_release.kube_prometheus_stack]
}
