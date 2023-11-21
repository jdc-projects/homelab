resource "kubernetes_persistent_volume_claim" "ocis" {
  for_each = tomap({
    nats = tomap({
      name    = "nats"
      storage = "10Gi"
    })
    search = tomap({
      name    = "search"
      storage = "10Gi"
    })
    storagesystem = tomap({
      name    = "storagesystem"
      storage = "5Gi"
    })
    storageusers = tomap({
      name    = "storageusers"
      storage = "200Gi"
    })
    store = tomap({
      name    = "store"
      storage = "5Gi"
    })
    thumbnails = tomap({
      name    = "thumbnails"
      storage = "10Gi"
    })
    web = tomap({
      name    = "web"
      storage = "1Gi"
    })
  })

  metadata {
    name      = each.value.name
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
  }
}
