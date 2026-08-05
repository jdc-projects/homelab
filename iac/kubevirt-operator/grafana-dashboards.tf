# KubeVirt community Grafana dashboard (grafana.com #11748, "KubeVirt VM Info"
# by stoniko - the only KubeVirt-tagged dashboard on grafana.com as of
# 2026-08). Renders per-VM CPU / memory / storage IOPS / storage traffic /
# storage IO time / network traffic series exported by virt-handler on its
# /metrics endpoint (scraped via the ServiceMonitor in metrics.tf).
#
# Dashboard CRs are created via the shared iac/modules/grafana-dashboard
# helper, which owns the grafana instance-selector contract and the
# allowCrossNamespaceImport setting (single source of truth). grafana-operator
# v5 auto-assigns each dashboard to a folder named after the namespace of its
# GrafanaDashboard CR, so this lands in a "kubevirt" folder. (No
# "kubevirt-operator" namespace exists - the operator deploys into the shared
# "kubevirt" ns; the dashboard CR follows the operator owner there.)
#
# The dashboard ships a `datasource` template variable of type=prometheus
# (query=prometheus); grafana-operator's datasource sync binds it to the
# provisioned Prometheus instance automatically (same pattern as the velero
# dashboard in iac/velero/dashboards/).

module "kubevirt_dashboards" {
  source    = "../modules/grafana-dashboard"
  namespace = local.kubevirt_namespace

  dashboards = {
    for f in fileset("${path.module}/dashboards", "*.json") :
    trimsuffix(f, ".json") => file("${path.module}/dashboards/${f}")
  }
}
