resource "kubernetes_persistent_volume_claim" "ocis" {
  for_each = tomap({
    nats = tomap({
      storage = "10Gi"
    })
    search = tomap({
      storage = "10Gi"
    })
    storagesystem = tomap({
      storage = "5Gi"
    })
    storageusers = tomap({
      storage = "200Gi"
    })
    store = tomap({
      storage = "5Gi"
    })
    thumbnails = tomap({
      storage = "10Gi"
    })
    web = tomap({
      storage = "5Gi"
    })
  })

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.ocis.metadata[0].name
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
