resource "helm_release" "valkey" {
  name      = "valkey"
  namespace = kubernetes_namespace.posthog.metadata[0].name

  repository = "https://valkey.io/valkey-helm/"
  chart      = "valkey"
  version    = local.valkey_chart_version

  timeout = 300

  set = [
    { name = "resources.requests.cpu", value = "200m" },
    { name = "resources.requests.memory", value = "256Mi" },
    { name = "resources.limits.cpu", value = "500m" },
    { name = "resources.limits.memory", value = "512Mi" },
  ]
}
