resource "kubernetes_persistent_volume_claim" "supabase" {
  for_each = tomap({
    storage = tomap({
      storage = "10Gi"
      storage_class_name = "openebs-zfs-localpv-random-no-backup"
    })
    functions = tomap({
      storage = "10Gi"
      storage_class_name = "openebs-zfs-localpv-random-no-backup"
    })
    db = tomap({
      storage = "10Gi"
      storage_class_name = "openebs-zfs-localpv-random-no-backup"
    })
  })

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    storage_class_name = each.value.storage_class_name

    resources {
      requests = {
        storage = each.value.storage
      }
    }
  }

  lifecycle {
    prevent_destroy = false # *****

    ignore_changes = [spec[0].selector]
  }
}
