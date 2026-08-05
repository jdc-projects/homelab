resource "kubernetes_persistent_volume_claim" "crowdsec" {
  for_each = tomap({
    lapi-data = tomap({
      storage            = "1Gi"
      storage_class_name = "openebs-zfs-localpv-general-no-backup"
    })
    lapi-config = tomap({
      storage            = "1Gi"
      storage_class_name = "openebs-zfs-localpv-general"
    })
  })

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.crowdsec.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = each.value.storage_class_name

    resources {
      requests = {
        storage = each.value.storage
      }
    }
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [spec[0].selector]
  }
}
