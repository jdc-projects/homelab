resource "kubernetes_job" "loki_chown" {
  metadata {
    name      = "loki-chown"
    namespace = kubernetes_namespace.loki.metadata[0].name
  }

  spec {
    template {
      metadata {}

      spec {
        container {
          image = "alpine:3.20.0"
          name  = "loki-chown"

          command = ["sh", "-c", "chown -R 1000:1000 /export"]

          security_context {
            run_as_user = 0
          }

          volume_mount {
            mount_path = "/export"
            name       = "loki-data"
          }
        }

        volume {
          name = "loki-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.loki["minio"].metadata[0].name
          }
        }

        restart_policy = "Never"
      }
    }

    backoff_limit = 0
  }

  wait_for_completion = true

  timeouts {
    create = "5m"
    update = "5m"
  }
}

resource "helm_release" "loki" {
  name = "loki"

  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "6.6.2"

  namespace = kubernetes_namespace.loki.metadata[0].name

  timeout = 600

  set {
    name  = "loki.auth_enabled"
    value = "false"
  }

  set {
    name  = "loki.commonConfig.replication_factor"
    value = "1"
  }

  set {
    name  = "read.replicas"
    value = "1"
  }
  set {
    name  = "write.replicas"
    value = "1"
  }
  set {
    name  = "backend.replicas"
    value = "1"
  }

  set {
    name  = "monitoring.selfMonitoring.enabled"
    value = "false"
  }
  set {
    name  = "test.enabled"
    value = "false"
  }

  set {
    name  = "gateway.basicAuth.enabled"
    value = "true"
  }
  set_sensitive {
    name  = "gateway.basicAuth.username"
    value = random_password.gateway_username.result
  }
  set_sensitive {
    name  = "gateway.basicAuth.password"
    value = random_password.gateway_password.result
  }

  # disable affinity, since it can break updates
  set {
    name  = "write.affinity"
    value = ""
  }
  set {
    name  = "table.affinity"
    value = ""
  }
  set {
    name  = "read.affinity"
    value = ""
  }
  set {
    name  = "backend.affinity"
    value = ""
  }

  set {
    name  = "singleBinary.affinity"
    value = ""
  }
  set {
    name  = "gateway.affinity"
    value = ""
  }

  set {
    name  = "minio.enabled"
    value = "true"
  }
  set {
    name  = "minio.mode"
    value = "standalone"
  }
  set {
    name  = "minio.replicas"
    value = "1"
  }
  set {
    name  = "minio.drivesPerNode"
    value = "1"
  }
  set_sensitive {
    name  = "minio.rootUser"
    value = random_password.minio_root_username.result
  }
  set_sensitive {
    name  = "minio.rootPassword"
    value = random_password.minio_root_password.result
  }
  set {
    name  = "minio.persistence.enabled"
    value = "true"
  }
  set {
    name  = "minio.persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.loki["minio"].metadata[0].name
  }
  set {
    name  = "minio.persistence.size"
    value = kubernetes_persistent_volume_claim.loki["minio"].spec[0].resources[0].requests.storage
  }

  set {
    name  = "write.persistence.storageClass"
    value = "openebs-zfs-localpv-random-no-backup"
  }
  set {
    name  = "read.persistence.storageClass"
    value = "openebs-zfs-localpv-random-no-backup"
  }
  set {
    name  = "backend.persistence.storageClass"
    value = "openebs-zfs-localpv-random-no-backup"
  }
  set {
    name  = "singleBinary.persistence.storageClass"
    value = "openebs-zfs-localpv-random-no-backup"
  }

  depends_on = [
    kubernetes_job.loki_chown
  ]
}
