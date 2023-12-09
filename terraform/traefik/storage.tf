resource "kubernetes_persistent_volume_claim" "traefik" {
  metadata {
    name      = "traefik"
    namespace = kubernetes_namespace.traefik.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteMany"]

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
