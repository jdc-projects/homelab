resource "helm_release" "velero" {
  name = "velero"

  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = "4.1.3"

  namespace = kubernetes_namespace.velero.metadata[0].name

  timeout = 300

  set {
    name  = "configuration.backupStorageLocation[0].name"
    value = ""
  }
  set {
    name  = "configuration.backupStorageLocation[0].provider"
    value = ""
  }
  set {
    name  = "configuration.backupStorageLocation[0].bucket"
    value = ""
  }
  set {
    name  = "configuration.backupStorageLocation[0].default"
    value = "true"
  }
  set {
    name  = "configuration.backupStorageLocation[0].credential.name"
    value = ""
  }
  set {
    name  = "configuration.backupStorageLocation[0].credential.key"
    value = ""
  }
  set {
    name  = "configuration.backupStorageLocation[0].config.*****"
    value = ""
  }

  set {
    name  = "configuration.volumeSnapshotLocation[0].name"
    value = ""
  }
  set {
    name  = "configuration.volumeSnapshotLocation[0].provider"
    value = ""
  }
  set {
    name  = "configuration.volumeSnapshotLocation[0].config.*****"
    value = ""
  }

  set {
    name  = "configuration.uploaderType"
    value = "kopia"
  }
  set {
    name  = "configuration.defaultBackupStorageLocation"
    value = ""
  }
  set {
    name  = "configuration.defaultBackupStorageLocation"
    value = ""
  }
  set {
    name  = "configuration.logLevel"
    value = "info"
  }
  set {
    name  = "configuration.features"
    value = "EnableCSI"
  }
  set {
    name  = "configuration.namespace"
    value = ""
  }

  set {
    name  = "deployNodeAgent"
    value = "true"
  }

  set {
    name  = "credentials.*****"
    value = ""
  }

  set {
    name  = "schedules.*****"
    value = ""
  }
}
