resource "kubernetes_manifest" "velero_restore" {
  count = var.restore_mode ? 1 : 0

  manifest = {
    apiVersion = "velero.io/v1"
    kind       = "IngressRoute"

    metadata = {
      name      = "${local.nightly_backup_name}-backup-restore-${timestamp()}"
      namespace = kubernetes_namespace.velero.metadata[0].name
    }

    spec = {
      # The unique name of the Velero schedule
      # to restore from. If specified, and BackupName is empty, Velero will
      # restore from the most recent successful backup created from this schedule.
      scheduleName = local.nightly_backup_name

      # Whether or not to include cluster-scoped resources. Valid values are true, false, and
      # null/unset. If true, all cluster-scoped resources are included (subject to included/excluded
      # resources and the label selector). If false, no cluster-scoped resources are included. If unset,
      # all cluster-scoped resources are included if and only if all namespaces are included and there are
      # no excluded namespaces. Otherwise, if there is at least one namespace specified in either
      # includedNamespaces or excludedNamespaces, then the only cluster-scoped resources that are backed
      # up are those associated with namespace-scoped resources included in the restore. For example, if a
      # PersistentVolumeClaim is included in the restore, its associated PersistentVolume (which is
      # cluster-scoped) would also be backed up.
      includeClusterResources = true

      # restorePVs specifies whether to restore all included PVs
      # from snapshot. Optional
      restorePVs = true
      # existingResourcePolicy specifies the restore behaviour
      # for the Kubernetes resource to be restored. Optional
      existingResourcePolicy = "update"
    }
  }
}
