locals {
  n8n_db_instances = 2
}

resource "kubernetes_manifest" "n8n_db" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"

    metadata = {
      name      = "n8n-db"
      namespace = kubernetes_namespace.n8n.metadata[0].name

      labels = {
        "velero.io/exclude-from-backup" = "true"
      }

      annotations = {
        "cnpg.io/hibernation" = var.is_db_hibernate ? "on" : "off"
      }
    }

    spec = {
      imageName = "ghcr.io/cloudnative-pg/postgresql:16.14-standard-trixie"

      instances = local.n8n_db_instances

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
          database = "n8n"
          owner    = random_password.n8n_db_username.result
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
          # Idle homelab DB: peak usage 12-70m measured 2026-08-29. 150m is
          # 2x+ headroom; the old 500m/instance starved the node (99% CPU
          # requests) and blocked xitter-prod's first apply from scheduling.
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
      "status.phase"                                      = "Cluster in healthy state"
      "status.danglingPVC[${local.n8n_db_instances - 1}]" = "*"
      } : {
      "status.phase"                                     = "Cluster in healthy state"
      "status.readyInstances"                            = local.n8n_db_instances
      "status.healthyPVC[${local.n8n_db_instances - 1}]" = "*"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
