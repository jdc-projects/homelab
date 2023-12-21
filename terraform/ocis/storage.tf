resource "kubernetes_persistent_volume_claim" "ocis" {
  for_each = tomap({
    nats = tomap({
      storage            = "10Gi"
      storage_class_name = "openebs-zfs-localpv-general"
    })
    search = tomap({
      storage            = "10Gi"
      storage_class_name = "openebs-zfs-localpv-general"
    })
    storagesystem = tomap({
      storage            = "5Gi"
      storage_class_name = "openebs-zfs-localpv-random"
    })
    storageusers = tomap({
      storage            = "200Gi"
      storage_class_name = "openebs-zfs-localpv-bulk"
    })
    store = tomap({
      storage            = "5Gi"
      storage_class_name = "openebs-zfs-localpv-random"
    })
    thumbnails = tomap({
      storage            = "10Gi"
      storage_class_name = "openebs-zfs-localpv-random"
    })
    web = tomap({
      storage            = "5Gi"
      storage_class_name = "openebs-zfs-localpv-random"
    })
  })

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = each.value.storage_class

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
