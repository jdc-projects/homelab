resource "helm_release" "loki" {
  name = "loki"

  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "5.9.0"

  namespace = kubernetes_namespace.loki.metadata[0].name

  timeout = 300

  set {
    name  = "loki.auth_enabled"
    value = "false"
  }

  set {
    name  = "loki.commonConfig.replication_factor"
    value = "1"
  }

  set {
    name  = "read.replicas"
    value = "1"
  }
  set {
    name  = "write.replicas"
    value = "1"
  }
  set {
    name  = "backend.replicas"
    value = "1"
  }

  set {
    name  = "monitoring.selfMonitoring.enabled"
    value = "false"
  }
  set {
    name  = "test.enabled"
    value = "false"
  }

  set {
    name  = "gateway.basicAuth.enabled"
    value = "true"
  }
  set {
    name  = "gateway.basicAuth.username"
    value = random_password.gateway_username.result
  }
  set {
    name  = "gateway.basicAuth.password"
    value = random_password.gateway_password.result
  }

  # disable affinity, since it can break updates
  set {
    name  = "write.affinity"
    value = ""
  }
  set {
    name  = "table.affinity"
    value = ""
  }
  set {
    name  = "read.affinity"
    value = ""
  }
  set {
    name  = "backend.affinity"
    value = ""
  }
  set {
    name  = "singleBinary.affinity"
    value = ""
  }
  set {
    name  = "gateway.affinity"
    value = ""
  }

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
    name  = "minio.persistence.size"
    value = "5Gi"
  }
}
