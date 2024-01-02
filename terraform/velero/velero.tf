resource "null_resource" "velero_version" {
  triggers = {
    velero_version = "5.2.0"
  }
}

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
  version    = null_resource.velero_version.triggers.velero_version

  namespace = kubernetes_namespace.velero.metadata[0].name

  timeout = 300

  set {
    name  = "resources.requests.cpu"
    value = "2"
  }
  set {
    name  = "resources.requests.memory"
    value = "4Gi"
  }
  set {
    name  = "resources.limits.cpu"
    value = "2"
  }
  set {
    name  = "resources.limits.memory"
    value = "4Gi"
  }

  set {
    name  = "initContainers[0].name"
    value = "velero-plugin-for-aws"
  }
  set {
    name  = "initContainers[0].image"
    value = "velero/velero-plugin-for-aws:v1.8.2"
  }
  set {
    name  = "initContainers[0].imagePullPolicy"
    value = "IfNotPresent"
  }
  set {
    name  = "initContainers[0].volumeMounts[0].mountPath"
    value = "/target"
  }
  set {
    name  = "initContainers[0].volumeMounts[0].name"
    value = "plugins"
  }
  set {
    name  = "initContainers[1].name"
    value = "velero-plugin-for-csi"
  }
  set {
    name  = "initContainers[1].image"
    value = "velero/velero-plugin-for-csi:v0.6.2"
  }
  set {
    name  = "initContainers[1].imagePullPolicy"
    value = "IfNotPresent"
  }
  set {
    name  = "initContainers[1].volumeMounts[0].mountPath"
    value = "/target"
  }
  set {
    name  = "initContainers[1].volumeMounts[0].name"
    value = "plugins"
  }

  set {
    name  = "cleanUpCRDs"
    value = "true"
  }

  set {
    name  = "configuration.backupStorageLocation[0].name"
    value = "backblaze"
  }
  set {
    name  = "configuration.backupStorageLocation[0].provider"
    value = "aws"
  }
  set {
    name  = "configuration.backupStorageLocation[0].bucket"
    value = var.velero_s3_bucket_name
  }
  set {
    name  = "configuration.backupStorageLocation[0].prefix"
    value = "velero"
  }
  set {
    name  = "configuration.backupStorageLocation[0].default"
    value = "true"
  }
  set {
    name  = "configuration.backupStorageLocation[0].accessMode"
    value = var.is_restore_mode ? "ReadOnly" : "ReadWrite"
  }
  set {
    name  = "configuration.backupStorageLocation[0].credential.name"
    value = kubernetes_secret.velero_s3_secret.metadata[0].name
  }
  set {
    name  = "configuration.backupStorageLocation[0].credential.key"
    value = "cloud"
  }
  set {
    name  = "configuration.backupStorageLocation[0].config.region"
    value = var.velero_s3_region
  }
  set {
    name  = "configuration.backupStorageLocation[0].config.s3ForcePathStyle"
    value = "true"
  }
  set {
    name  = "configuration.backupStorageLocation[0].config.s3Url"
    value = var.velero_s3_url
  }

  set {
    name  = "configuration.backupSyncPeriod"
    value = "10m"
  }
  set {
    name  = "configuration.fsBackupTimeout"
    value = "23h"
  }
  set {
    name  = "configuration.defaultBackupStorageLocation"
    value = "backblaze"
  }
  set {
    name  = "configuration.defaultBackupTTL"
    value = "720h"
  }
  set {
    name  = "configuration.logLevel"
    value = "info"
  }
  set {
    name  = "configuration.pluginDir"
    value = "/plugins"
  }
  set {
    name  = "configuration.restoreOnlyMode"
    value = var.is_restore_mode ? "true" : "false"
  }
  set {
    name  = "configuration.storeValidationFrequency"
    value = "10m"
  }
  set {
    name  = "configuration.features"
    value = "EnableCSI"
  }
  set {
    name  = "configuration.defaultSnapshotMoveData"
    value = "true"
  }
  set {
    name  = "configuration.namespace"
    value = kubernetes_namespace.velero.metadata[0].name
  }
  set {
    name  = "configuration.defaultVolumesToFsBackup"
    value = "false"
  }
  set {
    name  = "configuration.defaultRepoMaintainFrequency"
    value = "24h"
  }

  set {
    name  = "credentials.existingSecret"
    value = kubernetes_secret.velero_s3_secret.metadata[0].name
  }

  set {
    name  = "snapshotsEnabled"
    value = "false"
  }

  set {
    name  = "deployNodeAgent"
    value = "true"
  }

  set {
    name  = "nodeAgent.resources.requests.cpu"
    value = "4"
  }
  set {
    name  = "nodeAgent.resources.requests.memory"
    value = "4Gi"
  }
  set {
    name  = "nodeAgent.resources.limits.cpu"
    value = "4"
  }
  set {
    name  = "nodeAgent.resources.limits.memory"
    value = "4Gi"
  }

  lifecycle {
    replace_triggered_by  = [null_resource.velero_version]
    create_before_destroy = false
  }
}
