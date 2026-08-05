module "clickhouse_dashboards" {
  source    = "../modules/grafana-dashboard"
  namespace = kubernetes_namespace.clickhouse_operator.metadata[0].name

  dashboards = {
    for f in fileset("${path.module}/dashboards", "*.json") :
    trimsuffix(f, ".json") => file("${path.module}/dashboards/${f}")
  }
}
