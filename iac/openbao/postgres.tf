locals {
  openbao_db_instances = 2
}

# OpenBao's durable storage: the postgresql storage backend (production-ready
# since OpenBao 2.x, HA-capable as of 2.7.0). OpenBao's own docs recommend
# PostgreSQL as the easier-to-operate backend vs Raft, and it keeps this
# module on the standard per-service CNPG pattern (backups via volumeSnapshot,
# velero excluded, participates in the hibernation workflow like every other
# DB — OpenBao simply can't serve while its DB is asleep, same trade-off as
# every other app here).
resource "kubernetes_manifest" "openbao_db" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"

    metadata = {
      name      = "openbao-db"
      namespace = kubernetes_namespace.openbao.metadata[0].name

      labels = {
        "velero.io/exclude-from-backup" = "true"
      }

      annotations = {
        "cnpg.io/hibernation" = var.is_db_hibernate ? "on" : "off"
      }
    }

    spec = {
      # https://github.com/cloudnative-pg/postgres-containers/pkgs/container/postgresql
      imageName = "ghcr.io/cloudnative-pg/postgresql:16.14-standard-trixie"

      instances = local.openbao_db_instances

      monitoring = {
        enablePodMonitor = true
      }

      postgresql = {
        parameters = {
          shared_buffers = "256MB"
        }
      }

      bootstrap = {
        initdb = {
          database = "openbao"
          owner    = random_password.openbao_db_username.result
          secret = {
            name = kubernetes_secret.db_credentials.metadata[0].name
          }
        }
      }

      storage = {
        storageClass = "openebs-zfs-localpv-random"
        size         = "5Gi"

        pvcTemplate = {
          accessModes = [
            "ReadWriteOnce",
          ]
        }
      }

      backup = {
        volumeSnapshot = {
          className = "openebs-zfs-localpv"
        }
      }

      resources = {
        requests = {
          cpu    = "150m"
          memory = "1Gi"
        }

        limits = {
          cpu    = "500m"
          memory = "1Gi"
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
    fields = var.is_db_hibernate ? {
      "status.phase"                                          = "Cluster in healthy state"
      "status.danglingPVC[${local.openbao_db_instances - 1}]" = "*"
      } : {
      "status.phase"                                         = "Cluster in healthy state"
      "status.readyInstances"                                = local.openbao_db_instances
      "status.healthyPVC[${local.openbao_db_instances - 1}]" = "*"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
