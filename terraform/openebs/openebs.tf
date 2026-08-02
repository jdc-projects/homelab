resource "helm_release" "openebs" {
  name = "openebs"

  repository = "https://openebs.github.io/openebs"
  chart      = "openebs"
  version    = "4.5.1"

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
    # Disable the hostpath localpv storage engine - nothing uses it, all
    # storage goes through zfs-localpv. Prevents the chart from creating
    # the openebs-hostpath storage class and localpv-provisioner deployment.
    {
      name  = "engines.local.hostpath.enabled"
      value = "false"
    },
  ]
}
