resource "helm_release" "sentry" {
  name      = "sentry"
  namespace = kubernetes_namespace.sentry.metadata[0].name

  repository = "https://sentry-kubernetes.github.io/charts"
  chart      = "sentry"
  version    = "27.8.1"

  timeout = 1800

  set = [
    {
      name  = "user.email"
      value = "admin@sentry.local"
    },
    {
      name  = "system.url"
      value = "https://${local.sentry_domain}"
    },
    {
      name  = "system.adminEmail"
      value = "admin@sentry.local" # *****
    },
    {
      name  = "postgresql.enabled"
      value = "false"
    },
    {
      name  = "redis.enabled"
      value = "false"
    },
    {
      name  = "clickhouse.enabled"
      value = "false"
    },
    # {
    #   name  = "clickhouse.clickhouse.persistentVolumeClaim.enabled"
    #   value = "false" # *****
    # },
    {
      name  = "kafka.controller.persistence.storageClass"
      value = "openebs-zfs-localpv-general"
    },
    {
      name  = "kafka.broker.persistence.storageClass"
      value = "openebs-zfs-localpv-general"
    },
    {
      name  = "externalPostgresql.host"
      value = "${kubernetes_manifest.sentry_db.manifest.metadata.name}-rw"
    },
    {
      name  = "externalRedis.host"
      value = helm_release.valkey.name
    },
    {
      name  = "externalClickhouse.host"
      value = "clickhouse-${kubernetes_manifest.clickhouse.manifest.metadata.name}"
    },
    {
      name  = "externalClickhouse.singleNode"
      value = "true"
    },
    {
      name  = "filestore.filesystem.persistence.enabled"
      value = "true"
    },
    {
      name  = "filestore.filesystem.persistence.storageClass"
      value = "openebs-zfs-localpv-general"
    },
    {
      name  = "sentry.singleOrganization"
      value = "true"
    },
    {
      name  = "vroom.persistence.storageClass"
      value = "openebs-zfs-localpv-general-no-backup"
    },
    {
      name  = "geodata.persistence.storageClass"
      value = "openebs-zfs-localpv-general-no-backup"
    },
    {
      name  = "zookeeper.enabled"
      value = "false"
    },
    {
      name  = "rabbitmq.persistence.storageClass"
      value = "openebs-zfs-localpv-general-no-backup"
    }
  ]

  set_sensitive = [
    {
      name  = "user.password"
      value = random_password.sentry_admin_password.result
    },
    {
      name  = "system.secretKey"
      value = random_password.sentry_secret_key.result
    },
    {
      name  = "externalPostgresql.username"
      value = random_password.sentry_db_username.result
    },
    {
      name  = "externalPostgresql.password"
      value = random_password.sentry_db_password.result
    }
  ]

  lifecycle {
    prevent_destroy = false # ***** kafka is the limiting factor here
    # ***** can I use existing pvcs for Kafka?
  }
}
