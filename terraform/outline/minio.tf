locals {
  minio_domain      = "minio-${local.outline_domain}"
  minio_bucket_name = "data"
}

resource "kubernetes_job" "minio_chown" {
  metadata {
    name      = "minio-chown"
    namespace = kubernetes_namespace.outline.metadata[0].name
  }

  spec {
    template {
      metadata {}

      spec {
        container {
          image = "alpine:3.22.2"
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
  version    = "5.4.0"

  namespace = kubernetes_namespace.outline.metadata[0].name

  timeout = 300

  set = [
    {
      name  = "mode"
      value = "standalone"
    },
    {
      name  = "replicas"
      value = "1"
    },
    {
      name  = "drivesPerNode"
      value = "1"
    },
    {
      name  = "persistence.enabled"
      value = "true"
    },
    {
      name  = "persistence.existingClaim"
      value = kubernetes_persistent_volume_claim.minio.metadata[0].name
    },
    {
      name  = "persistence.size"
      value = kubernetes_persistent_volume_claim.minio.spec[0].resources[0].requests.storage
    },
    {
      name  = "ingress.enabled"
      value = "false"
    },
    {
      name  = "resources.requests.cpu"
      value = "100m"
    },
    {
      name  = "resources.requests.memory"
      value = "1G"
    },
    {
      name  = "resources.limits.cpu"
      value = "200m"
    },
    {
      name  = "resources.limits.memory"
      value = "2G"
    },
    {
      name  = "users[0].policy"
      value = "readwrite"
    },
    {
      name  = "buckets[0].name"
      value = local.minio_bucket_name
    },
    {
      name  = "buckets[0].policy"
      value = "none"
    },
    {
      name  = "buckets[0].purge"
      value = "false"
    },
    {
      name  = "buckets[0].versioning"
      value = "false"
    },
    {
      name  = "buckets[0].objectlocking"
      value = "false"
    },
    {
      name  = "customCommands[0].command"
      value = "anonymous set download myminio/${local.minio_bucket_name}/public/*"
    },
  ]

  set_sensitive = [
    {
      name  = "rootUser"
      value = random_password.minio_root_username.result
    },
    {
      name  = "rootPassword"
      value = random_password.minio_root_password.result
    },
    {
      name  = "users[0].accessKey"
      value = random_password.minio_access_key.result
    },
    {
      name  = "users[0].secretKey"
      value = random_password.minio_secret_key.result
    },
  ]

  depends_on = [
    kubernetes_job.minio_chown
  ]
}

module "minio_ingress" {
  source = "../modules/ingress"

  name      = "minio"
  namespace = kubernetes_namespace.outline.metadata[0].name
  domain    = local.minio_domain

  target_port = 9000

  existing_service_name      = helm_release.minio.name
  existing_service_namespace = helm_release.minio.namespace
}
