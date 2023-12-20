resource "kubernetes_persistent_volume_claim" "harbor" {
  for_each = tomap({
    minio = tomap({
      storage = "5Gi"
      storage_class_name = "openebs-zfs-localpv-random"
    })
    jobservice = tomap({
      storage = "5Gi"
      storage_class_name = "openebs-zfs-localpv-random"
    })
    redis = tomap({
      storage = "5Gi"
      storage_class_name = "openebs-zfs-localpv-random"
    })
    trivy = tomap({
      storage = "5Gi"
      storage_class_name = "openebs-zfs-localpv-random"
    })
  })

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.harbor.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteMany"]
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
