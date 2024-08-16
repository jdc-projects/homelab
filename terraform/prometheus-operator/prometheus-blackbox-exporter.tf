resource "helm_release" "prometheus_blackbox_exporter" {
  name      = "prometheus-blackbox-exporter"
  namespace = kubernetes_namespace.prometheus_operator.metadata[0].name

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-blackbox-exporter"
  version    = "9.0.0"

  timeout = 300

  depends_on = [
    helm_release.prometheus_operator,
  ]
}
