resource "kubernetes_persistent_volume_claim" "prowler_output" {
  metadata {
    name      = "prowler-output"
    namespace = kubernetes_namespace.prowler.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "openebs-zfs-localpv-general"

    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [spec[0].selector]
  }
}
