resource "kubernetes_persistent_volume_claim" "fission" {

  metadata {
    name      = "fission"
    namespace = kubernetes_namespace.fission["core"].metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "openebs-zfs-localpv-general-no-backup"

    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = false

    ignore_changes = [spec[0].selector]
  }
}
