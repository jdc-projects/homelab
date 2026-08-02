# Velero community Grafana dashboard (grafana.com #11055, "Kubernetes /
# Addons / Velero Stats" by mischenkovn). Renders backup/restore/schedule
# metrics exported by the velero server and scraped via the ServiceMonitor /
# PodMonitor enabled in velero.tf.
#
# Dashboard CRs are created via the shared terraform/modules/grafana-dashboard
# helper, which owns the grafana instance-selector contract and the
# allowCrossNamespaceImport setting (single source of truth). grafana-operator
# v5 auto-assigns each dashboard to a folder named after its namespace, so this
# lands in a "velero" folder.

module "velero_dashboards" {
  source    = "../modules/grafana-dashboard"
  namespace = kubernetes_namespace.velero.metadata[0].name

  dashboards = {
    for f in fileset("${path.module}/dashboards", "*.json") :
    trimsuffix(f, ".json") => file("${path.module}/dashboards/${f}")
  }

  depends_on = [helm_release.velero]
}
