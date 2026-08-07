locals {
  nightly_backup_name = "nightly"
}

resource "kubernetes_secret" "velero_s3_secret" {
  metadata {
    name      = "velero-s3-secret"
    namespace = kubernetes_namespace.velero.metadata[0].name
  }

  data = {
    cloud = <<-EOF
      [default]
      aws_access_key_id=${var.velero_s3_access_key_id}
      aws_secret_access_key=${var.velero_s3_secret_access_key}
    EOF
  }
}

resource "helm_release" "velero" {
  name = "velero"

  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"
  version    = "12.1.0"

  namespace = kubernetes_namespace.velero.metadata[0].name

  timeout = 300

  set = [
    {
      name  = "resources.requests.cpu"
      value = "100m"
    },
    {
      name  = "resources.requests.memory"
      value = "256Mi"
    },
    {
      name  = "resources.limits.cpu"
      value = "2"
    },
    {
      name  = "resources.limits.memory"
      value = "4Gi"
    },
    {
      name  = "initContainers[0].name"
      value = "velero-plugin-for-aws"
    },
    # Pinned: velero-plugin-for-aws v1.14.x sends an empty `x-amz-tagging` header on
    # PutObject, which Backblaze B2 (and other strict S3-compatible stores) reject with
    # HTTP 400 -> every backup fails uploading velero-backup.json. Regression introduced
    # in v1.14.1; v1.13.2 is the last known-good release.
    # Upstream issue: https://github.com/velero-io/velero/issues/9931
    # Fix PR (still open): https://github.com/velero-io/velero-plugin-for-aws/pull/304
    #   (#299 is merged but incomplete and is NOT included in v1.14.2.)
    # TODO: bump back to the latest release once a tag > v1.14.2 ships PR #304.
    {
      name  = "initContainers[0].image"
      value = "velero/velero-plugin-for-aws:v1.13.2"
    },
    {
      name  = "initContainers[0].imagePullPolicy"
      value = "IfNotPresent"
    },
    {
      name  = "initContainers[0].volumeMounts[0].mountPath"
      value = "/target"
    },
    {
      name  = "initContainers[0].volumeMounts[0].name"
      value = "plugins"
    },
    {
      name  = "initContainers[1].name"
      value = "kubevirt-velero-plugin"
    },
    {
      name  = "initContainers[1].image"
      value = "quay.io/kubevirt/kubevirt-velero-plugin:v0.9.0"
    },
    {
      name  = "initContainers[1].imagePullPolicy"
      value = "IfNotPresent"
    },
    {
      name  = "initContainers[1].volumeMounts[0].mountPath"
      value = "/target"
    },
    {
      name  = "initContainers[1].volumeMounts[0].name"
      value = "plugins"
    },
    {
      name  = "upgradeCRDs"
      value = "true"
    },
    {
      name  = "cleanUpCRDs"
      value = "false"
    },
    {
      name  = "configuration.backupStorageLocation[0].name"
      value = "backblaze"
    },
    {
      name  = "configuration.backupStorageLocation[0].provider"
      value = "aws"
    },
    {
      name  = "configuration.backupStorageLocation[0].bucket"
      value = var.velero_s3_bucket_name
    },
    {
      name  = "configuration.backupStorageLocation[0].prefix"
      value = "velero"
    },
    {
      name  = "configuration.backupStorageLocation[0].default"
      value = "true"
    },
    {
      name  = "configuration.backupStorageLocation[0].accessMode"
      value = var.is_restore_mode ? "ReadOnly" : "ReadWrite"
    },
    {
      name  = "configuration.backupStorageLocation[0].credential.name"
      value = kubernetes_secret.velero_s3_secret.metadata[0].name
    },
    {
      name  = "configuration.backupStorageLocation[0].credential.key"
      value = "cloud"
    },
    {
      name  = "configuration.backupStorageLocation[0].config.region"
      value = var.velero_s3_region
    },
    {
      name  = "configuration.backupStorageLocation[0].config.s3ForcePathStyle"
      value = "true"
    },
    {
      name  = "configuration.backupStorageLocation[0].config.s3Url"
      value = var.velero_s3_url
    },
    {
      name  = "configuration.backupSyncPeriod"
      value = "10m"
    },
    {
      name  = "configuration.fsBackupTimeout"
      value = "23h"
    },
    {
      name  = "configuration.defaultBackupStorageLocation"
      value = "backblaze"
    },
    {
      name  = "configuration.defaultBackupTTL"
      value = "8760h"
    },
    {
      name  = "configuration.logLevel"
      value = "info"
    },
    {
      name  = "configuration.pluginDir"
      value = "/plugins"
    },
    {
      name  = "configuration.restoreOnlyMode"
      value = var.is_restore_mode ? "true" : "false"
    },
    {
      name  = "configuration.storeValidationFrequency"
      value = "10m"
    },
    {
      name  = "configuration.features"
      value = "EnableCSI"
    },
    {
      name  = "configuration.defaultSnapshotMoveData"
      value = "true"
    },
    {
      name  = "configuration.namespace"
      value = kubernetes_namespace.velero.metadata[0].name
    },
    {
      name  = "configuration.defaultVolumesToFsBackup"
      value = "false"
    },
    {
      name  = "configuration.defaultRepoMaintainFrequency"
      value = "8h"
    },
    {
      name  = "credentials.existingSecret"
      value = kubernetes_secret.velero_s3_secret.metadata[0].name
    },
    {
      name  = "snapshotsEnabled"
      value = "false"
    },
    {
      name  = "deployNodeAgent"
      value = "true"
    },
    {
      name  = "metrics.serviceMonitor.enabled"
      value = "true"
    },
    {
      name  = "metrics.nodeAgentPodMonitor.enabled"
      value = "true"
    },
    {
      name  = "nodeAgent.resources.requests.cpu"
      value = "100m"
    },
    {
      name  = "nodeAgent.resources.requests.memory"
      value = "256Mi"
    },
    {
      name  = "nodeAgent.resources.limits.cpu"
      value = "4"
    },
    {
      name  = "nodeAgent.resources.limits.memory"
      value = "4Gi"
    },
  ]
}
