# Community Grafana dashboards for the PostHog stack.
#
# Dashboards live as JSON files under iac/posthog/dashboards/ and are
# turned into GrafanaDashboard CRs by the ../modules/grafana-dashboard helper.
module "posthog_dashboards" {
  source = "../modules/grafana-dashboard"

  namespace = kubernetes_namespace.posthog.metadata[0].name

  dashboards = {
    for f in fileset("${path.module}/dashboards", "*.json") :
    trimsuffix(f, ".json") => file("${path.module}/dashboards/${f}")
  }
}
