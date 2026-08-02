# Curated Loki dashboard for Grafana.
#
# Source: grafana.com #13639 ("Loki Logs / App") — a log viewer for Loki
# that lets you filter by the `job` label and substring-match log lines.
# Downloads: ~16M. Verified to query the Loki datasource via ${DS_LOKI}.
#
# Dashboard CRs are created via the shared terraform/modules/grafana-dashboard
# helper, which owns the grafana instance-selector contract and the
# allowCrossNamespaceImport setting (single source of truth). grafana-operator
# v5 auto-assigns each dashboard to a folder named after its namespace, so
# these land in a "loki" folder.

module "loki_dashboards" {
  source    = "../modules/grafana-dashboard"
  namespace = kubernetes_namespace.loki.metadata[0].name

  dashboards = {
    for f in fileset("${path.module}/dashboards-loki", "*.json") :
    trimsuffix(f, ".json") => file("${path.module}/dashboards-loki/${f}")
  }

  depends_on = [helm_release.loki]
}
