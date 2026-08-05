# PVC for the inline RustFS instance. Traces are disposable telemetry, so this
# lands on the same `openebs-zfs-localpv-random-no-backup` class used by
# Prometheus/Loki (no backup, fast) rather than the `bulk` class the
# outline/posthog RustFS instances use (those hold user data). Mirrors the PVC
# pattern in terraform/outline/storage.tf.
resource "kubernetes_persistent_volume_claim" "rustfs" {
  metadata {
    name      = "rustfs"
    namespace = kubernetes_namespace.tempo.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "openebs-zfs-localpv-random-no-backup"

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
