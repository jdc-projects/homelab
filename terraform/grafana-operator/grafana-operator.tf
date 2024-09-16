resource "helm_release" "grafana_operator" {
  name      = "grafana-operator"
  namespace = kubernetes_namespace.grafana_operator.metadata[0].name

  repository = "oci://ghcr.io/grafana/helm-charts"
  chart      = "grafana-operator"
  version    = "v5.13.0"

  timeout = 300
}
