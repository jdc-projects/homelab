resource "helm_release" "openebs" {
  name = "openebs"

  repository = "https://openebs.github.io/openebs"
  chart      = "openebs"
  version    = "3.10.0"

  namespace = kubernetes_namespace.openebs.metadata[0].name

  timeout = 300

  set {
    name  = "zfs-localpv.enabled"
    value = "true"
  }
}
