resource "kubernetes_persistent_volume_claim" "supabase" {
  for_each = tomap({
    storage = tomap({
      storage = "10Gi"
    })
    functions = tomap({
      storage = "10Gi"
    })
    db = tomap({
      storage = "10Gi"
    })
  })

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.supabase.metadata[0].name
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
    prevent_destroy = false # *****

    ignore_changes = [spec[0].selector]
  }
}
