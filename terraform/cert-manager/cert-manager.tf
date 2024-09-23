resource "helm_release" "cert_manager" {
  name = "cert-manager"

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.15.3"

  namespace = kubernetes_namespace.cert_manager.metadata[0].name

  timeout = 300

  set {
    name  = "crds.enabled"
    value = "true"
  }
}
