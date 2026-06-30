resource "helm_release" "loki" {
  name = "loki"

  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "7.0.0"

  namespace = kubernetes_namespace.loki.metadata[0].name

  timeout = 600

  set = [
    {
      name  = "loki.auth_enabled"
      value = "false"
    },
    {
      name  = "loki.commonConfig.replication_factor"
      value = "1"
    },
    {
      name  = "loki.storage.bucketNames.chunks"
      value = "chunks"
    },
    {
      name  = "read.replicas"
      value = "1"
    },
    {
      name  = "write.replicas"
      value = "1"
    },
    {
      name  = "backend.replicas"
      value = "1"
    },
    {
      name  = "monitoring.selfMonitoring.enabled"
      value = "false"
    },
    {
      name  = "test.enabled"
      value = "false"
    },
    {
      name  = "gateway.basicAuth.enabled"
      value = "true"
    },
    {
      name  = "write.affinity"
      value = ""
    },
    {
      name  = "table.affinity"
      value = ""
    },
    {
      name  = "read.affinity"
      value = ""
    },
    {
      name  = "backend.affinity"
      value = ""
    },
    {
      name  = "singleBinary.affinity"
      value = ""
    },
    {
      name  = "gateway.affinity"
      value = ""
    },
    {
      name  = "minio.enabled"
      value = "true"
    },
    {
      name  = "minio.mode"
      value = "standalone"
    },
    {
      name  = "minio.replicas"
      value = "1"
    },
    {
      name  = "minio.drivesPerNode"
      value = "1"
    },
    {
      name  = "write.persistence.size"
      value = "20Gi"
    },
    {
      name  = "write.persistence.storageClass"
      value = "openebs-zfs-localpv-random-no-backup"
    },
    {
      name  = "read.persistence.size"
      value = "10Gi"
    },
    {
      name  = "read.persistence.storageClass"
      value = "openebs-zfs-localpv-random-no-backup"
    },
    {
      name  = "backend.persistence.size"
      value = "10Gi"
    },
    {
      name  = "backend.persistence.storageClass"
      value = "openebs-zfs-localpv-random-no-backup"
    },
    {
      name  = "minio.persistence.enabled"
      value = "true"
    },
    {
      name  = "minio.persistence.size"
      value = "20Gi"
    },
    {
      name  = "minio.persistence.storageClass"
      value = "openebs-zfs-localpv-random-no-backup"
    },
  ]

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

  set_sensitive = [
    {
      name  = "gateway.basicAuth.username"
      value = random_password.loki_gateway_username.result
    },
    {
      name  = "gateway.basicAuth.password"
      value = random_password.loki_gateway_password.result
    },
    {
      name  = "minio.rootUser"
      value = random_password.loki_minio_root_username.result
    },
    {
      name  = "minio.rootPassword"
      value = random_password.loki_minio_root_password.result
    }
  ]
}
