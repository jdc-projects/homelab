resource "kubernetes_persistent_volume_claim" "traefik" {
  metadata {
    name      = "traefik"
    namespace = kubernetes_namespace.traefik.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "openebs-zfs-localpv-random-no-backup"

    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = false

    ignore_changes = [spec[0].selector]
  }
}
