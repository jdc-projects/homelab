resource "kubernetes_manifest" "velero_restore" {
  count = var.restore_mode ? 1 : 0

  manifest = {
    apiVersion = "velero.io/v1"
    kind       = "Restore"

    metadata = {
      name      = "velero-${local.nightly_backup_name}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
      namespace = kubernetes_namespace.velero.metadata[0].name
    }

    spec = {
      backupName = ""

      # The unique name of the Velero schedule
      # to restore from. If specified, and BackupName is empty, Velero will
      # restore from the most recent successful backup created from this schedule.
      scheduleName = "velero-${local.nightly_backup_name}"

      itemOperationTimeout = "23h"

      excludedNamespaces = [
        "default",
        "kube-system",
        "kube-public",
        "kube-node-lease",
      ]

      includeClusterResources = true

      # restorePVs specifies whether to restore all included PVs
      # from snapshot. Optional
      restorePVs = true
      # existingResourcePolicy specifies the restore behaviour
      # for the Kubernetes resource to be restored. Optional
      existingResourcePolicy = "update"
    }
  }

  depends_on = [helm_release.velero]
}
