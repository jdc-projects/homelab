# Canonical cert-manager Grafana dashboard, rendered from the
# imusmanmalik/cert-manager-mixin Jsonnet sources (the mixin referenced from the
# official cert-manager docs at https://cert-manager.io/docs/devops-tips/prometheus-metrics/
# under "Monitoring Mixin") and pre-rendered by monitoring-mixins/website. This
# is the source-of-truth community dashboard for cert-manager; the commonly
# mis-cited grafana.com ID #14300 is unrelated (a Kaspersky/Zabbix dashboard)
# and is intentionally NOT used here.
#
# The dashboard queries the certmanager_* Prometheus metrics exported by the
# cert-manager controller on :9402/metrics (Certificate Ready Status,
# Certificate Expiration, ACME client requests, controller sync call count,
# etc.), scraped via the ServiceMonitor enabled in cert-manager.tf.
#
# Dashboard CRs are created via the shared terraform/modules/grafana-dashboard
# helper, which owns the grafana instance-selector contract and the
# allowCrossNamespaceImport setting (single source of truth). grafana-operator
# v5 auto-assigns each dashboard to a folder named after its namespace, so this
# lands in a "cert-manager" folder.

module "certmanager_dashboards" {
  source    = "../modules/grafana-dashboard"
  namespace = kubernetes_namespace.cert_manager.metadata[0].name

  dashboards = {
    for f in fileset("${path.module}/dashboards", "*.json") :
    trimsuffix(f, ".json") => file("${path.module}/dashboards/${f}")
  }

  depends_on = [helm_release.cert_manager]
}
