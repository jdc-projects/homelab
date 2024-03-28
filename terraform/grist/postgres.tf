locals {
  grist_db_instances = 1
}

resource "kubernetes_manifest" "grist_db" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"

    metadata = {
      name      = "grist-db"
      namespace = kubernetes_namespace.grist.metadata[0].name

      labels = {
        "velero.io/exclude-from-backup" = "true"
      }

      annotations = {
        "cnpg.io/hibernation" = var.is_db_hibernate ? "on" : "off"
      }
    }

    spec = {
      # https://github.com/cloudnative-pg/postgres-containers/pkgs/container/postgresql
      imageName = "ghcr.io/cloudnative-pg/postgresql:16.1-16"

      instances = local.grist_db_instances

      postgresql = {
        parameters = {
          shared_buffers = "256MB"
        }
      }

      bootstrap = {
        initdb = {
          database = "grist"
          owner    = random_password.grist_db_username.result
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

      resources = {
        requests = {
          cpu    = "4"
          memory = "4Gi"
        }

        limits = {
          cpu    = "4"
          memory = "4Gi"
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
      "status.phase"                                        = "Cluster in healthy state"
      "status.danglingPVC[${local.grist_db_instances - 1}]" = "*"
      } : {
      "status.phase"                                       = "Cluster in healthy state"
      "status.readyInstances"                              = local.grist_db_instances
      "status.healthyPVC[${local.grist_db_instances - 1}]" = "*"
    }
  }

  lifecycle {
    prevent_destroy = false # *****
  }
}
