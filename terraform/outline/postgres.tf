locals {
  outline_db_instances = 2
}

resource "kubernetes_manifest" "outline_db" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"

    metadata = {
      name      = "outline-db"
      namespace = kubernetes_namespace.outline.metadata[0].name

      labels = {
        "velero.io/exclude-from-backup" = "true"
      }

      annotations = {
        "cnpg.io/hibernation" = var.is_db_hibernate ? "on" : "off"
      }
    }

    spec = {
      # https://github.com/cloudnative-pg/postgres-containers/pkgs/container/postgresql
      imageName = "ghcr.io/cloudnative-pg/postgresql:16.4-31"

      instances = local.outline_db_instances

      postgresql = {
        parameters = {
          shared_buffers = "256MB"
        }
      }

      bootstrap = {
        initdb = {
          database = "outline"
          owner    = random_password.outline_db_username.result
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

  computed_fields = [
    "metadata.labels",
    "metadata.annotations",
    "spec.postgresql.parameters",
  ]

  wait {
    fields = var.is_db_hibernate ? {
      "status.phase"                                          = "Cluster in healthy state"
      "status.danglingPVC[${local.outline_db_instances - 1}]" = "*"
      } : {
      "status.phase"                                         = "Cluster in healthy state"
      "status.readyInstances"                                = local.outline_db_instances
      "status.healthyPVC[${local.outline_db_instances - 1}]" = "*"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
