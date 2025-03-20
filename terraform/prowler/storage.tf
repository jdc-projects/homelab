resource "kubernetes_persistent_volume_claim" "valkey" {
  metadata {
    name      = "valkey"
    namespace = kubernetes_namespace.prowler.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "openebs-zfs-localpv-random"

    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = false # *****

    ignore_changes = [spec[0].selector]
  }
}

resource "kubernetes_persistent_volume_claim" "prowler_api_output" {
  metadata {
    name      = "prowler-api-output"
    namespace = kubernetes_namespace.prowler.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "openebs-zfs-localpv-general"

    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = false # *****

    ignore_changes = [spec[0].selector]
  }
}
