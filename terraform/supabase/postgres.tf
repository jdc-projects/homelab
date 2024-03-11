locals {
  supabase_db_instances = 2
}

resource "kubernetes_manifest" "supabase_db" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"

    metadata = {
      name      = "supabase-db"
      namespace = kubernetes_namespace.supabase.metadata[0].name

      labels = {
        "velero.io/exclude-from-backup" = "true"
      }

      annotations = {
        "cnpg.io/hibernation" = var.is_db_hibernate ? "on" : "off"
      }
    }

    spec = {
      imageName = docker_image.postgres.name

      instances = local.supabase_db_instances

      postgresql = {
        parameters = {
          shared_buffers = "256MB"
        }
      }

      bootstrap = {
        initdb = {
          database = "supabase"
          owner    = random_password.supabase_db_username.result
          secret = {
            name = kubernetes_secret.db_credentials.metadata[0].name
          }
        }
      }

      envFrom = {
        secretRef = "" # *****
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
      "status.phase"                                           = "Cluster in healthy state"
      "status.danglingPVC[${local.supabase_db_instances - 1}]" = "*"
      } : {
      "status.phase"                                          = "Cluster in healthy state"
      "status.readyInstances"                                 = local.supabase_db_instances
      "status.healthyPVC[${local.supabase_db_instances - 1}]" = "*"
    }
  }

  lifecycle {
    prevent_destroy = false # *****
  }
}
