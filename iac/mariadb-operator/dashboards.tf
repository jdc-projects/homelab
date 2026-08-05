module "mariadb_dashboards" {
  source    = "../modules/grafana-dashboard"
  namespace = kubernetes_namespace.mariadb_operator.metadata[0].name

  dashboards = {
    for f in fileset("${path.module}/dashboards", "*.json") :
    trimsuffix(f, ".json") => file("${path.module}/dashboards/${f}")
  }

  depends_on = [helm_release.mariadb_operator]
}
