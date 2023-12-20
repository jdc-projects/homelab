resource "kubernetes_persistent_volume_claim" "runners" {
  for_each = tomap({
    tool-cache = tomap({
      storage = "10Gi"
      storage_class_name = "openebs-zfs-localpv-random-no-backup"
    })
  })

  metadata {
    name      = each.key
    namespace = data.terraform_remote_state.github_org_runners_1.outputs.github_org_runners_namespace_name
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = each.value.storage_class_name

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
