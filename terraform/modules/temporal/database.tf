resource "kubernetes_manifest" "temporal_db" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"

    metadata = {
      name      = "${var.name_prefix}-db"
      namespace = var.namespace

      annotations = {
        "cnpg.io/hibernation" = var.is_db_hibernate ? "on" : "off"
      }
    }

    spec = {
      imageName = var.db_image

      instances = var.db_instances

      postgresql = {
        parameters = {
          shared_buffers = "128MB"
        }
      }

      bootstrap = {
        initdb = {
          database = "temporal"
          owner    = "temporal"
          secret = {
            name = kubernetes_secret.temporal_db_credentials.metadata[0].name
          }
        }
      }

      storage = {
        storageClass = "openebs-zfs-localpv-random"
        size         = "5Gi"

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
          cpu    = "250m"
          memory = "512Mi"
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
      "status.phase"                                = "Cluster in healthy state"
      "status.danglingPVC[${var.db_instances - 1}]" = "*"
      } : {
      "status.phase"                               = "Cluster in healthy state"
      "status.readyInstances"                      = var.db_instances
      "status.healthyPVC[${var.db_instances - 1}]" = "*"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
