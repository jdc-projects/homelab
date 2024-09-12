resource "helm_release" "loki" {
  name = "loki"

  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "6.12.0"

  namespace = kubernetes_namespace.loki.metadata[0].name

  timeout = 600

  set {
    name  = "loki.auth_enabled"
    value = "false"
  }

  # this is the neatest way to put in the schema_config(s)
  values = [
    <<-EOF
      loki:
        schemaConfig:
          configs:
            - from: 2024-04-01
              object_store: s3
              store: tsdb
              schema: v13
              index:
                prefix: index_
                period: 24h
    EOF
  ]

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
  set_sensitive {
    name  = "gateway.basicAuth.username"
    value = random_password.gateway_username.result
  }
  set_sensitive {
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
    name  = "minio.mode"
    value = "standalone"
  }
  set {
    name  = "minio.replicas"
    value = "1"
  }
  set {
    name  = "minio.drivesPerNode"
    value = "1"
  }
  set_sensitive {
    name  = "minio.rootUser"
    value = random_password.minio_root_username.result
  }
  set_sensitive {
    name  = "minio.rootPassword"
    value = random_password.minio_root_password.result
  }

  set {
    name  = "write.persistence.storageClass"
    value = "openebs-zfs-localpv-random-no-backup"
  }
  set {
    name  = "read.persistence.storageClass"
    value = "openebs-zfs-localpv-random-no-backup"
  }
  set {
    name  = "backend.persistence.storageClass"
    value = "openebs-zfs-localpv-random-no-backup"
  }
  set {
    name  = "singleBinary.persistence.storageClass"
    value = "openebs-zfs-localpv-random-no-backup"
  }
  set {
    name  = "minio.persistence.enabled"
    value = "true"
  }
  set {
    name  = "minio.persistence.storageClass"
    value = "openebs-zfs-localpv-random-no-backup"
  }
}
