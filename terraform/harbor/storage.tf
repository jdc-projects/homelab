resource "kubernetes_persistent_volume_claim" "harbor" {
  for_each = tomap({
    minio = tomap({
      name    = "minio"
      storage = "5Gi"
    })
    jobservice = tomap({
      name    = "jobservice"
      storage = "1Gi"
    })
    database = tomap({
      name    = "database"
      storage = "1Gi"
    })
    redis = tomap({
      name    = "redis"
      storage = "1Gi"
    })
    trivy = tomap({
      name    = "trivy"
      storage = "5Gi"
    })
  })

  metadata {
    name      = each.value.name
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
    prevent_destroy = true
  }
}
