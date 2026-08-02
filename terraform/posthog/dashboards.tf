# Community Grafana dashboards for the PostHog stack.
#
# Dashboards live as JSON files under terraform/posthog/dashboards/ and are
# turned into GrafanaDashboard CRs by the ../modules/grafana-dashboard helper.
# grafana-operator then picks them up via its instanceSelector and renders them
# in the operator-managed Grafana instance.
#
# To add a new dashboard:
#   1. Drop a `<name>.json` file in this directory (next to the others).
#   2. Re-run `terraform apply`. The for_each below picks it up automatically.
#
# Verified dashboard IDs (community/grafana.com):
#   - kafka-exporter.json  -> gnetId 7589 "Kafka Exporter Overview"
#                             (matches strimzi kafka-exporter pod metrics)
#   - clickhouse-queries.json -> gnetId 2515 "ClickHouse Queries" by Altinity
#                                (requires the Altinity plugin for ClickHouse
#                                datasource; panels render once that datasource
#                                is configured in Grafana)
module "posthog_dashboards" {
  source = "../modules/grafana-dashboard"

  namespace = kubernetes_namespace.posthog.metadata[0].name

  dashboards = {
    for f in fileset("${path.module}/dashboards", "*.json") :
    trimsuffix(f, ".json") => file("${path.module}/dashboards/${f}")
  }
}
