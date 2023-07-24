resource "helm_release" "oauth2_proxy" {
  name = "loki"

  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "5.9.0"

  namespace = kubernetes_namespace.loki.metadata[0].name

  timeout = 300

  set {
    name  = "minio.enabled"
    value = "true"
  }
  set {
    name  = "minio.rootUser"
    value = random_password.minio_root_username.result
  }
  set {
    name  = "minio.rootPassword"
    value = random_password.minio_root_password.result
  }
  set {
    name  = "minio.persistence.existingClaim"
    value = "" # *****
  }
  set {
    name  = "minio.persistence.volumeName"
    value = "minio-data"
  }
  set {
    name  = "minio.persistence.size"
    value = "5Gi"
  }
  set {
    name  = "minio.podAnnotations.backup\\.velero\\.io\\/backup-volumes"
    value = "minio-data"
  }
}