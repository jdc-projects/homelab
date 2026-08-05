locals {
  mariadb_replicas = 2
}

resource "kubernetes_manifest" "erpnext_db_recovery_template" {
  manifest = {
    apiVersion = "k8s.mariadb.com/v1alpha1"
    kind       = "PhysicalBackup"

    metadata = {
      name      = "erpnext-db-recovery-template"
      namespace = kubernetes_namespace.erpnext.metadata[0].name
    }

    spec = {
      mariaDbRef = {
        name      = "erpnext-db"
        waitForIt = false
      }

      schedule = {
        suspend = true
      }

      target = "PreferReplica"

      storage = {
        volumeSnapshot = {
          volumeSnapshotClassName = "openebs-zfs-localpv"
        }
      }
    }
  }
}

resource "kubernetes_manifest" "erpnext_db" {
  manifest = {
    apiVersion = "k8s.mariadb.com/v1alpha1"
    kind       = "MariaDB"

    metadata = {
      name      = "erpnext-db"
      namespace = kubernetes_namespace.erpnext.metadata[0].name

      labels = {
        "velero.io/exclude-from-backup" = "true"
      }
    }

    spec = {
      image = "mariadb:12.3.2"

      replicas = local.mariadb_replicas

      rootPasswordSecretKeyRef = {
        name = kubernetes_secret.mariadb_root_password.metadata[0].name
        key  = "password"
      }

      storage = {
        storageClassName = "openebs-zfs-localpv-random"
        size             = "10Gi"

        volumeClaimTemplate = {
          accessModes = ["ReadWriteOnce"]
        }
      }

      replication = {
        enabled = true

        replica = {
          bootstrapFrom = {
            physicalBackupTemplateRef = {
              name = "erpnext-db-recovery-template"
            }
          }

          recovery = {
            enabled                = true
            errorDurationThreshold = "5m"
          }
        }
      }

      metrics = {
        enabled = true

        passwordSecretKeyRef = {
          name = kubernetes_secret.mariadb_metrics_password.metadata[0].name
          key  = "password"
        }
      }

      suspend = false
    }
  }

  computed_fields = [
    "metadata.labels",
    "metadata.annotations",
    "spec.suspend",
    "spec.metrics",
  ]

  field_manager {
    force_conflicts = true
  }

  lifecycle {
    prevent_destroy = true
  }

  wait {
    fields = {
      "status.currentPrimary" = "*"
      "status.replicas"       = local.mariadb_replicas
    }
  }

  depends_on = [kubernetes_manifest.erpnext_db_recovery_template]
}
