resource "kubernetes_persistent_volume_claim" "loki_minio" {
  metadata {
    name      = "loki-minio"
    namespace = kubernetes_namespace.loki.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteMany"]

    resources {
      requests = {
        storage = "50Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
