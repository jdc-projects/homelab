resource "kubernetes_manifest" "velero_restore" {
  manifest = {
    apiVersion = "velero.io/v1"
    kind       = "Restore"

    metadata = {
      name      = "${data.terraform_remote_state.velero.outputs.nightly_backup_name}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
      namespace = data.terraform_remote_state.velero.outputs.velero_namespace_name
    }

    spec = {
      backupName              = ""
      scheduleName            = data.terraform_remote_state.velero.outputs.nightly_backup_name
      itemOperationTimeout    = "23h"
      includeClusterResources = true
      existingResourcePolicy  = "update"
    }
  }

  wait {
    fields = {
      "status.phase" = "Completed"
    }
  }

  timeouts {
    create = "23h"
  }
}
