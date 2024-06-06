resource "helm_release" "openebs" {
  name = "openebs"

  repository = "https://openebs.github.io/openebs"
  chart      = "openebs"
  version    = "4.0.1"

  namespace = kubernetes_namespace.openebs.metadata[0].name

  timeout = 300

  set {
    name  = "zfs-localpv.enabled"
    value = "true"
  }

  set {
    name = "lvm-localpv.enabled"
    value = "false"
  }

  set {
    name = "mayastor.enabled"
    value = "false"
  }

  set {
    name = "engines.local.lvm.enabled"
    value = "false"
  }
  set {
    name = "engines.replicated.mayastor.enabled"
    value = "false"
  }
}
