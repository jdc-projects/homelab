resource "kubernetes_manifest" "sentry_db" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"

    metadata = {
      name      = "sentry-db"
      namespace = kubernetes_namespace.sentry.metadata[0].name

      labels = {
        "velero.io/exclude-from-backup" = "true"
      }

      annotations = {
        "cnpg.io/hibernation" = var.is_db_hibernate ? "on" : "off"
      }
    }

    spec = {
      imageName = "ghcr.io/cloudnative-pg/postgresql:16.11-standard-trixie"

      instances = 2

      postgresql = {
        parameters = {
          shared_buffers = "256MB"
        }
      }

      bootstrap = {
        initdb = {
          database = "sentry"
          owner    = random_password.sentry_db_username.result
          secret = {
            name = kubernetes_secret.db_credentials.metadata[0].name
          }
        }
      }

      storage = {
        storageClass = "openebs-zfs-localpv-random"
        size         = "10Gi"

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
          cpu    = "500m"
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
  ]

  wait {
    fields = var.is_db_hibernate ? {
      "status.phase"                 = "Cluster in healthy state"
      "status.danglingPVC[${2 - 1}]" = "*"
      } : {
      "status.phase"                = "Cluster in healthy state"
      "status.readyInstances"       = 2
      "status.healthyPVC[${2 - 1}]" = "*"
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}
