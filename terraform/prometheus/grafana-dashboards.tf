# Curated Grafana dashboards for K3s.
#
# Extracted from kube-prometheus-stack (same version as pinned in
# terraform/prometheus-operator/). The 4 component-specific dashboards that
# reference per-component job labels are included with K8s-compatible job
# label fixes applied.
#
# To update: re-render the chart with forceDeployDashboards, extract the
# ConfigMap dashboard JSONs, diff against existing files, and replace.
#
# Dashboard CRs are created via the shared terraform/modules/grafana-dashboard
# helper, which owns the grafana instance-selector contract and the
# allowCrossNamespaceImport setting (single source of truth). grafana-operator
# v5 auto-assigns each dashboard to a folder named after its namespace, so these
# land in a "prometheus" folder.

module "grafana_dashboards" {
  source    = "../modules/grafana-dashboard"
  namespace = kubernetes_namespace.prometheus.metadata[0].name

  dashboards = {
    for f in fileset("${path.module}/dashboards", "*.json") :
    trimsuffix(f, ".json") => file("${path.module}/dashboards/${f}")
  }

  depends_on = [helm_release.kube_prometheus_stack]
}
