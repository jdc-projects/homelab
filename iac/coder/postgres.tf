locals {
  coder_db_instances = 2
}

resource "kubernetes_manifest" "coder_db" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"

    metadata = {
      name      = "coder-db"
      namespace = kubernetes_namespace.coder.metadata[0].name

      annotations = {
        "cnpg.io/hibernation" = var.is_db_hibernate ? "on" : "off"
      }
    }

    spec = {
      # https://github.com/cloudnative-pg/postgres-containers/pkgs/container/postgresql
      imageName = "ghcr.io/cloudnative-pg/postgresql:16.14-standard-trixie"

      instances = local.coder_db_instances

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
          database = "coder"
          owner    = random_password.coder_db_username.result
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
      "status.phase"                                        = "Cluster in healthy state"
      "status.danglingPVC[${local.coder_db_instances - 1}]" = "*"
      } : {
      "status.phase"                                       = "Cluster in healthy state"
      "status.readyInstances"                              = local.coder_db_instances
      "status.healthyPVC[${local.coder_db_instances - 1}]" = "*"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
