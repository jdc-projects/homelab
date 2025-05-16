resource "kubernetes_persistent_volume_claim" "omada" {
  metadata {
    name      = "omada"
    namespace = kubernetes_namespace.omada.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "openebs-zfs-localpv-general"

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
