# Curated Grafana dashboards for K3s.
#
# Extracted from kube-prometheus-stack v88.1.2. The 4 component-specific
# dashboards (apiserver, controller-manager, scheduler, proxy) and irrelevant
# ones (AIX, Darwin, multicluster, windows) are excluded - they reference
# per-component job labels that don't exist on K3s. The remaining 22
# dashboards use job="kubelet" (with metrics_path) or job="etcd"/"coredns"
# which match our ScrapeConfig configuration.
#
# To update: re-render the chart with forceDeployDashboards, extract the
# ConfigMap dashboard JSONs, diff against existing files, and replace.

locals {
  dashboard_files = fileset("${path.module}/dashboards", "*.json")
}

resource "kubernetes_manifest" "grafana_dashboard" {
  for_each = local.dashboard_files

  manifest = {
    apiVersion = "grafana.integreatly.org/v1beta1"
    kind       = "GrafanaDashboard"

    metadata = {
      name      = trimsuffix(each.value, ".json")
      namespace = kubernetes_namespace.prometheus.metadata[0].name
    }

    spec = {
      allowCrossNamespaceImport = "true"

      instanceSelector = {
        matchLabels = data.terraform_remote_state.grafana.outputs.grafana_deployment_labels
      }

      json = file("${path.module}/dashboards/${each.value}")
    }
  }

  depends_on = [helm_release.kube_prometheus_stack]
}
