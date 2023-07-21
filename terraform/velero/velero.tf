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
  version    = "4.1.3"

  namespace = kubernetes_namespace.velero.metadata[0].name

  timeout = 300

  set {
    name  = "initContainers[0].name"
    value = "velero-plugin-for-aws"
  }
  set {
    name  = "initContainers[0].image"
    value = "velero/velero-plugin-for-aws:v1.7.0"
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
    name  = "configuration.backupStorageLocation[0].default"
    value = "true"
  }
  set {
    name  = "configuration.backupStorageLocation[0].accessMode"
    value = var.restore_mode ? "ReadOnly" : "ReadWrite"
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
    name  = "configuration.uploaderType"
    value = "kopia"
  }
  set {
    name  = "configuration.fsBackupTimeout"
    value = "23h"
  }
  set {
    name  = "configuration.defaultBackupStorageLocation"
    value = "backblaze-b2"
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
    value = var.restore_mode ? "true" : "false"
  }
  set {
    name  = "configuration.namespace"
    value = kubernetes_namespace.velero.metadata[0].name
  }
  set {
    name  = "configuration.defaultVolumesToFsBackup"
    value = "true"
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
    name  = "nodeAgent.resources"
    value = ""
  }

  set {
    name  = "schedules.nightly.disabled"
    value = "false"
  }
  set {
    name  = "schedules.nightly.schedule"
    value = "35 12 * * *"
  }
  set {
    name  = "schedules.nightly.useOwnerReferencesInBackup"
    value = "false"
  }
  set {
    name  = "schedules.nightly.template.includedNamespaces[0]"
    value = "*"
  }
  set {
    name  = "schedules.nightly.template.excludedNamespaces[0]"
    value = "default"
  }
  set {
    name  = "schedules.nightly.template.excludedNamespaces[1]"
    value = "kube-system"
  }
  set {
    name  = "schedules.nightly.template.excludedNamespaces[2]"
    value = "kube-public"
  }
  set {
    name  = "schedules.nightly.template.excludedNamespaces[3]"
    value = "kube-node-lease"
  }
  set {
    name  = "schedules.nightly.template.excludedNamespaces[4]"
    value = "openebs"
  }
  set {
    name  = "schedules.nightly.template.excludedNamespaces[5]"
    value = "velero"
  }
  set {
    name  = "schedules.nightly.template.includeClusterResources"
    value = "false"
  }
  set {
    name  = "schedules.nightly.template.snapshotVolumes"
    value = "false"
  }
  set {
    name  = "schedules.nightly.template.storageLocation"
    value = "backblaze"
  }
  set {
    name  = "schedules.nightly.template.ttl"
    value = "240h"
  }
  set {
    name  = "schedules.nightly.template.defaultVolumesToFsBackup"
    value = "false"
  }
}
