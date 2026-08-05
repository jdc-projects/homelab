resource "helm_release" "valkey" {
  name      = "valkey"
  namespace = kubernetes_namespace.n8n.metadata[0].name

  repository = "https://valkey.io/valkey-helm/"
  chart      = "valkey"
  version    = "0.10.0"

  timeout = 300

  set = [
    { name = "metrics.enabled", value = "true" },
    { name = "metrics.serviceMonitor.enabled", value = "true" },
  ]
}
