resource "kubernetes_persistent_volume_claim" "n8n_data" {
  metadata {
    name      = "n8n-data"
    namespace = kubernetes_namespace.n8n.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    storage_class_name = "openebs-zfs-localpv-general"

    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      spec[0].selector
    ]
  }
}
