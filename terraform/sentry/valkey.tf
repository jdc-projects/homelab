resource "helm_release" "valkey" {
  name      = "valkey"
  namespace = kubernetes_namespace.sentry.metadata[0].name

  repository = "https://valkey.io/valkey-helm/"
  chart      = "valkey"
  version    = "0.8.1"

  timeout = 300

  # ***** can I use existing pvcs?

  set = [
    {
      name  = "master.persistence.enabled"
      value = "true"
    },
    {
      name  = "master.persistence.storageClass"
      value = "openebs-zfs-localpv-random"
    },
    {
      name  = "replica.persistence.enabled"
      value = "true"
    },
    {
      name  = "replica.persistence.storageClass"
      value = "openebs-zfs-localpv-random"
    }
  ]

  lifecycle {
    prevent_destroy = false
  }
}
