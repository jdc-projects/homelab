# Curated grafana-operator dashboard for Grafana.
#
# Source: grafana.com #22785 ("Grafana Operator") — operator health and
# managed-resource status dashboard. Verified to query grafana_operator_*
# metrics (reconciles, initial sync durations, grafana api requests) plus
# the usual go_*/process_*/workqueue_*/rest_client_requests_total set.
#
# Cluster-specific patches applied vs upstream:
#   - namespace filter changed from "monitoring-system" to "grafana-operator"
#     (where the operator pod actually runs here).
#   - ,$k8sClusterLabelKey="$cluster" matcher removed: this cluster has no
#     `cluster=` label on operator metrics, so the multi-cluster filter
#     would zero out every series.
#   - the now-meaningless `cluster` / `k8sClusterLabelKey` template vars are
#     hidden (hide=2) so the UI doesn't try to populate them from empty
#     label_values queries.
#
# Dashboard CRs are created via the shared terraform/modules/grafana-dashboard
# helper, which owns the grafana instance-selector contract and the
# allowCrossNamespaceImport setting (single source of truth). grafana-operator
# v5 auto-assigns each dashboard to a folder named after its namespace, so
# these land in a "grafana-operator" folder.

module "go_dashboards" {
  source    = "../modules/grafana-dashboard"
  namespace = kubernetes_namespace.grafana_operator.metadata[0].name

  dashboards = {
    for f in fileset("${path.module}/dashboards", "*.json") :
    trimsuffix(f, ".json") => file("${path.module}/dashboards/${f}")
  }

  depends_on = [helm_release.grafana_operator]
}
