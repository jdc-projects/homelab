resource "kubernetes_persistent_volume_claim" "redis" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.affine.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "openebs-zfs-localpv-random"

    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [spec[0].selector]
  }
}

resource "kubernetes_persistent_volume_claim" "affine" {
  for_each = tomap({
    config = tomap({
      storage            = "1Gi"
      storage_class_name = "openebs-zfs-localpv-general"
    })
    storage = tomap({
      storage            = "10Gi"
      storage_class_name = "openebs-zfs-localpv-bulk"
    })
  })

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.affine.metadata[0].name
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
