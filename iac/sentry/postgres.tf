locals {
  sentry_db_instances = 2

  # PgBouncer pooler service — the host the Sentry chart points at
  # (externalPostgresql.host). Uses transaction mode to match the PostHog module
  # (posthog-db-pooler), which runs Django over it with zero connection errors.
  # Session mode caused intermittent "SSL connection has been closed unexpectedly"
  # errors under the chart's CONN_MAX_AGE=0 (per-request reconnect) churn.
  pg_host = kubernetes_manifest.sentry_db_pooler.manifest.metadata.name
}

resource "kubernetes_manifest" "sentry_db" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"

    metadata = {
      name      = "sentry-db"
      namespace = local.ns
    }

    spec = {
      imageName = local.postgres_image

      instances = local.sentry_db_instances

      monitoring = {
        enablePodMonitor = true
      }

      postgresql = {
        parameters = {
          shared_buffers  = "256MB"
          max_connections = "300"
        }
      }

      bootstrap = {
        initdb = {
          database = "sentry"
          owner    = "sentry"
          secret = {
            name = kubernetes_secret.sentry_db_credentials.metadata[0].name
          }
        }
      }

      storage = {
        storageClass = "openebs-zfs-localpv-random"
        size         = "20Gi"

        pvcTemplate = {
          accessModes = ["ReadWriteOnce"]
        }
      }

      backup = {
        volumeSnapshot = {
          className = "openebs-zfs-localpv"
        }
      }

      resources = {
        requests = {
          cpu    = "1"
          memory = "2Gi"
        }
        limits = {
          cpu    = "2"
          memory = "2Gi"
        }
      }

      primaryUpdateStrategy = "unsupervised"
      primaryUpdateMethod   = "switchover"

      logLevel = "info"
    }
  }

  field_manager {
    force_conflicts = true
  }

  computed_fields = [
    "metadata.labels",
    "metadata.annotations",
    "spec.postgresql.parameters",
    "spec.monitoring",
  ]

  wait {
    fields = {
      "status.phase"                                        = "Cluster in healthy state"
      "status.readyInstances"                               = local.sentry_db_instances
      "status.healthyPVC[${local.sentry_db_instances - 1}]" = "*"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_manifest" "sentry_db_pooler" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Pooler"

    metadata = {
      name      = "sentry-db-pooler"
      namespace = local.ns
    }

    spec = {
      cluster = {
        name = kubernetes_manifest.sentry_db.manifest.metadata.name
      }

      instances = 2

      type = "rw"

      pgbouncer = {
        poolMode = "transaction"
        parameters = {
          max_client_conn   = "1000"
          default_pool_size = "25"
          reserve_pool_size = "5"
        }
      }
    }
  }

  field_manager {
    force_conflicts = true
  }

  computed_fields = [
    "metadata.labels",
    "metadata.annotations",
  ]

  wait {
    fields = {
      "status.instances" = 2
    }
  }

  depends_on = [kubernetes_manifest.sentry_db]
}
