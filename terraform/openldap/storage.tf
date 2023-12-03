resource "kubernetes_persistent_volume_claim" "openldap" {
  metadata {
    name      = "openldap"
    namespace = kubernetes_namespace.openldap.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteMany"]

    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [spec.selector]
  }
}
