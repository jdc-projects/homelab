resource "kubernetes_persistent_volume_claim" "loki" {
  for_each = tomap({
    minio = tomap({
      name    = "minio"
      storage = "50Gi"
    })
  })

  metadata {
    name      = each.value.name
    namespace = kubernetes_namespace.loki.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteMany"]

    resources {
      requests = {
        storage = each.value.storage
      }
    }
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [spec[0].selector]
  }
}
