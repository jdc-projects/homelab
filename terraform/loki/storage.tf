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
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "truenas-nfs-csi-no-backup"

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
