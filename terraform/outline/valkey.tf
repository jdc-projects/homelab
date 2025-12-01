resource "helm_release" "valkey" {
  name      = "valkey"
  namespace = kubernetes_namespace.outline.metadata[0].name

  repository = "https://valkey.io/valkey-helm/"
  chart      = "valkey"
  version    = "0.8.1"

  timeout = 300
}
