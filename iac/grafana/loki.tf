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
      name  = "monitoring.serviceMonitor.enabled"
      value = "true"
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
    # The bundled minio subchart is unmaintained: minio/minio is archived (charts.min.io
    # is frozen at a Dec-2024 image). The community-maintained Loki chart will deprecate
    # and remove this built-in subchart (render-time guard on minio.enabled in chart 14.0.0;
    # migration is to external object storage, or a self-hosted RustFS/Garage). Track:
    #   https://github.com/grafana/loki/issues/19563
    #   https://github.com/grafana-community/helm-charts/issues/366
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
      value = "50Gi"
    },
    {
      name  = "minio.persistence.storageClass"
      value = "openebs-zfs-localpv-random-no-backup"
    },
  ]

  # this is the neatest way to put in the schema_config(s)
  # limits_config.allow_structured_metadata must be true for promtail's
  # structured_metadata stage to actually store (and make queryable) the traceId
  # via LogQL `| traceId="..."`. Defaults to false in Loki 3.x; v13/tsdb schema
  # supports it.  NOTE: the chart key is loki.limits_config (snake_case), read by
  # the chart's loki.config string template via `.Values.loki.limits_config`; the
  # camelCase loki.limitsConfig is silently ignored.  Helm deep-merges this map
  # over the chart's default limits_config (reject_old_samples, query_timeout,
  # volume_enabled, ...), so those are preserved.
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
        limits_config:
          allow_structured_metadata: true
          # Time-based retention (compactor-driven; see compactor block below).
          # At ~0.94 GiB/day of chunks this caps the minio PVC at a steady state
          # of ~28 GiB, leaving comfortable headroom under the 50Gi PVC.
          retention_period: 720h
          max_query_lookback: 720h
        compactor:
          retention_enabled: true
          # filesystem delete_request_store is fine here because the compactor runs
          # as a single backend replica (data-loki-backend-0); the boltdb lives on
          # its PVC. If backend.replicas is raised above 1, switch this to the
          # shared S3 store. working_directory defaults to /var/loki/compactor,
          # which is already on the persistent backend PVC.
          delete_request_store: filesystem
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
