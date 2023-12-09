resource "kubernetes_persistent_volume_claim" "oauth2_proxy" {
  metadata {
    name      = "oauth2-proxy"
    namespace = kubernetes_namespace.oauth2_proxy.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "truenas-nfs-csi-no-backup"

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
