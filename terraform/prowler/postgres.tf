locals {
  prowler_db_instances = 2
}

resource "kubernetes_manifest" "prowler_db" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"

    metadata = {
      name      = "prowler-db"
      namespace = kubernetes_namespace.prowler.metadata[0].name

      labels = {
        "velero.io/exclude-from-backup" = "true"
      }

      annotations = {
        "cnpg.io/hibernation" = var.is_db_hibernate ? "on" : "off"
      }
    }

    spec = {
      # https://github.com/cloudnative-pg/postgres-containers/pkgs/container/postgresql
      imageName = "ghcr.io/cloudnative-pg/postgresql:16.6-23"

      instances = local.prowler_db_instances

      postgresql = {
        parameters = {
          shared_buffers = "256MB"
        }
      }

      bootstrap = {
        initdb = {
          database = "prowler"
          owner    = random_password.prowler_db_username.result
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

      managed = {
        roles = [{
          name   = random_password.prowler_db_superuser_username.result
          ensure = "present"
          passwordSecret = {
            name = kubernetes_secret.db_superuser_credentials.metadata[0].name
          }
          superuser = true # ***** would be good to restrict beyond this
          # createdb = true
          # createrole = true
          login     = true
          # createrole = false
          # bypassrls = true
        }]
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
      "status.phase"                                          = "Cluster in healthy state"
      "status.danglingPVC[${local.prowler_db_instances - 1}]" = "*"
      } : {
      "status.phase"                                         = "Cluster in healthy state"
      "status.readyInstances"                                = local.prowler_db_instances
      "status.healthyPVC[${local.prowler_db_instances - 1}]" = "*"
    }
  }

  lifecycle {
    prevent_destroy = false # *****
  }
}
