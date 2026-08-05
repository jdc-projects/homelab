module "n8n_dashboards" {
  source    = "../modules/grafana-dashboard"
  namespace = kubernetes_namespace.n8n.metadata[0].name

  dashboards = {
    for f in fileset("${path.module}/dashboards", "*.json") :
    trimsuffix(f, ".json") => file("${path.module}/dashboards/${f}")
  }
}
