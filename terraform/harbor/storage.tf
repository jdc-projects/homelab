resource "kubernetes_persistent_volume_claim" "harbor" {
  for_each = tomap({
    minio = tomap({
      storage = "5Gi"
    })
    jobservice = tomap({
      storage = "5Gi"
    })
    redis = tomap({
      storage = "5Gi"
    })
    trivy = tomap({
      storage = "5Gi"
    })
  })

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.harbor.metadata[0].name
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
    prevent_destroy = false

    ignore_changes = [spec[0].selector]
  }
}
