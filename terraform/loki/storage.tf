resource "kubernetes_persistent_volume_claim" "loki" {
  for_each = tomap({
    minio = tomap({
      storage = "50Gi"
    })
  })

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.loki.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "openebs-zfs-localpv-random-no-backup"

    resources {
      requests = {
        storage = each.value.storage
      }
    }
  }

  lifecycle {
    prevent_destroy = false

    ignore_changes = [spec[0].selector]
  }
}
