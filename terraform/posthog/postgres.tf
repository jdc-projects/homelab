locals {
  posthog_db_instances = 2

  posthog_databases = [
    "posthog_persons",
    "cyclotron",
    "cyclotron_node",
    "behavioral_cohorts",
    "flags_read_store",
    "agent_runtime_queue",
    "ducklake",
  ]

  pg_host      = "${kubernetes_manifest.posthog_db.manifest.metadata.name}-rw"
  pg_base      = "postgres://posthog:${random_password.posthog_db_password.result}@${local.pg_host}:5432"
  database_url = "${local.pg_base}/posthog"
}

resource "kubernetes_manifest" "posthog_db" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"

    metadata = {
      name      = "posthog-db"
      namespace = kubernetes_namespace.posthog.metadata[0].name

      annotations = {
        "cnpg.io/hibernation" = var.is_db_hibernate ? "on" : "off"
      }
    }

    spec = {
      imageName = local.postgres_image

      instances = local.posthog_db_instances

      postgresql = {
        parameters = {
          shared_buffers  = "256MB"
          max_connections = "200"
        }
      }

      bootstrap = {
        initdb = {
          database = "posthog"
          owner    = "posthog"
          secret = {
            name = kubernetes_secret.posthog_db_credentials.metadata[0].name
          }

          postInitSQL = [
            for db in local.posthog_databases : "CREATE DATABASE ${db}"
          ]
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
  ]

  wait {
    fields = var.is_db_hibernate ? {
      "status.phase"                                          = "Cluster in healthy state"
      "status.danglingPVC[${local.posthog_db_instances - 1}]" = "*"
      } : {
      "status.phase"                                         = "Cluster in healthy state"
      "status.readyInstances"                                = local.posthog_db_instances
      "status.healthyPVC[${local.posthog_db_instances - 1}]" = "*"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
