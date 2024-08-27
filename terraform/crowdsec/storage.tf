resource "kubernetes_persistent_volume_claim" "crowdsec_lapi_data" {
  metadata {
    name      = "crowdsec-lapi-data"
    namespace = kubernetes_namespace.crowdsec.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "openebs-zfs-localpv-general-no-backup"

    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = false

    ignore_changes = [spec[0].selector]
  }
}
