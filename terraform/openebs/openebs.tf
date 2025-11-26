resource "helm_release" "openebs" {
  name = "openebs"

  repository = "https://openebs.github.io/openebs"
  chart      = "openebs"
  version    = "4.4.0"

  namespace = kubernetes_namespace.openebs.metadata[0].name

  timeout = 300

  set = [
    {
      name  = "zfs-localpv.enabled"
      value = "true"
    },
    {
      name  = "lvm-localpv.enabled"
      value = "false"
    },
    {
      name  = "mayastor.enabled"
      value = "false"
    },
    {
      name  = "engines.local.lvm.enabled"
      value = "false"
    },
    {
      name  = "engines.replicated.mayastor.enabled"
      value = "false"
    },
    {
      name  = "loki.enabled"
      value = "false"
    },
    {
      name  = "alloy.enabled"
      value = "false"
    },
  ]
}
