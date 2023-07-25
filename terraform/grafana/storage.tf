resource "kubernetes_persistent_volume_claim" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.grafana.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteMany"]

    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
