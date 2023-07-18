resource "kubernetes_persistent_volume_claim" "ocis" {
  metadata {
    name      = "ocis"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteMany"]

    resources {
      requests = {
        storage = "200Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
