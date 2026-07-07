resource "kubernetes_persistent_volume_claim" "erpnext_sites" {
  metadata {
    name      = "erpnext-sites"
    namespace = kubernetes_namespace.erpnext.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "openebs-zfs-localpv-general"

    resources {
      requests = {
        storage = "8Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [spec[0].selector]
  }
}
