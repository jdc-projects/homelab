resource "kubernetes_persistent_volume_claim" "trivy_report" {
  metadata {
    name      = "trivy-report"
    namespace = kubernetes_namespace.trivy.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteMany"]

    resources {
      requests = {
        storage = "128Mi"
      }
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}
