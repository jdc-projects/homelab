resource "kubernetes_persistent_volume_claim" "opnsense" {
  metadata {
    name      = "opnsense"
    namespace = kubernetes_namespace.opnsense.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "openebs-zfs-localpv-general-no-backup"

    resources {
      requests = {
        storage = "16Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [spec[0].selector]
  }
}
