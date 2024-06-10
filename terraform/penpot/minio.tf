locals {
  minio_domain      = "minio-${local.penpot_domain}"
  minio_bucket_name = "data"
}

resource "kubernetes_job" "minio_chown" {
  metadata {
    name      = "minio-chown"
    namespace = kubernetes_namespace.penpot.metadata[0].name
  }

  spec {
    template {
      metadata {}

      spec {
        container {
          image = "alpine:3.20.0"
          name  = "minio-chown"

          command = ["sh", "-c", "chown -R 1000:1000 /export"]

          security_context {
            run_as_user = 0
          }

          volume_mount {
            mount_path = "/export"
            name       = "minio-data"
          }
        }

        volume {
          name = "minio-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.minio.metadata[0].name
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

resource "helm_release" "minio" {
  name = "minio"

  repository = "https://charts.min.io/"
  chart      = "minio"
  version    = "5.2.0"

  namespace = kubernetes_namespace.penpot.metadata[0].name

  timeout = 300

  set {
    name  = "mode"
    value = "standalone"
  }

  set {
    name  = "replicas"
    value = "1"
  }
  set {
    name  = "drivesPerNode"
    value = "1"
  }

  set_sensitive {
    name  = "rootUser"
    value = random_password.minio_root_username.result
  }
  set_sensitive {
    name  = "rootPassword"
    value = random_password.minio_root_password.result
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }
  set {
    name  = "persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.minio.metadata[0].name
  }
  set {
    name  = "persistence.size"
    value = kubernetes_persistent_volume_claim.minio.spec[0].resources[0].requests.storage
  }

  set {
    name  = "ingress.enabled"
    value = "false"
  }

  set_sensitive {
    name  = "users[0].accessKey"
    value = random_password.minio_access_key.result
  }
  set_sensitive {
    name  = "users[0].secretKey"
    value = random_password.minio_secret_key.result
  }
  set {
    name  = "users[0].policy"
    value = "readwrite"
  }

  set {
    name  = "buckets[0].name"
    value = local.minio_bucket_name
  }
  set {
    name  = "buckets[0].policy"
    value = "none"
  }
  set {
    name  = "buckets[0].purge"
    value = "false"
  }
  set {
    name  = "buckets[0].versioning"
    value = "false"
  }
  set {
    name  = "buckets[0].objectlocking"
    value = "false"
  }

  depends_on = [
    kubernetes_job.minio_chown
  ]
}