resource "kubernetes_secret" "velero" {
  metadata {
    name      = "velero"
    namespace = kubernetes_namespace.velero.metadata[0].name
  }

  data = {
    S3_SECRET_ACCESS_KEY = var.velero_s3_secret_access_key
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
    name  = "configuration.backupStorageLocation[0].name"
    value = "backblaze-b2"
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
    name  = "configuration.backupStorageLocation[0].credential.name"
    value = kubernetes_secret.velero.metadata[0].name
  }
  set {
    name  = "configuration.backupStorageLocation[0].credential.key"
    value = "S3_SECRET_ACCESS_KEY"
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
    name  = "configuration.defaultBackupStorageLocation"
    value = "backblaze-b2"
  }
  set {
    name  = "configuration.logLevel"
    value = "info"
  }
  set {
    name  = "configuration.namespace"
    value = kubernetes_namespace.velero.metadata[0].name
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
    name  = "schedules.nightly.disabled"
    value = "false"
  }
  set {
    name  = "schedules.nightly.schedule"
    value = "0 4 * * *"
  }
}
