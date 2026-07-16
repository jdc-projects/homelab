# One-shot data migration: mirrors MinIO's `data` bucket into RustFS over
# in-cluster services (no Cloudflare/crowdsec hairpin). Plain --overwrite so the
# job terminates; re-run it (terraform taint kubernetes_job.rustfs_migrate) to
# catch any writes that happened between the initial copy and the cutover.
# Deleted in the cutover commit once MinIO is removed.
resource "kubernetes_job" "rustfs_migrate" {
  metadata {
    name      = "rustfs-migrate"
    namespace = kubernetes_namespace.outline.metadata[0].name
  }

  spec {
    template {
      metadata {}

      spec {
        restart_policy = "Never"

        container {
          image = "minio/mc:RELEASE.2025-08-13T08-35-41Z"
          name  = "rustfs-migrate"

          command = [
            "/bin/sh",
            "-c",
            <<-EOT
              mc alias set old http://minio:9000 "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY"
              mc alias set new http://rustfs-svc:9000 "$RUSTFS_ACCESS_KEY" "$RUSTFS_SECRET_KEY"
              mc mirror --overwrite old/${local.rustfs_bucket_name} new/${local.rustfs_bucket_name}
            EOT
          ]

          env {
            name  = "MINIO_ACCESS_KEY"
            value = random_password.minio_root_username.result
          }

          env {
            name  = "MINIO_SECRET_KEY"
            value = random_password.minio_root_password.result
          }

          env {
            name  = "RUSTFS_ACCESS_KEY"
            value = random_password.rustfs_root_username.result
          }

          env {
            name  = "RUSTFS_SECRET_KEY"
            value = random_password.rustfs_root_password.result
          }
        }
      }
    }

    backoff_limit = 0
  }

  wait_for_completion = true

  timeouts {
    create = "20m"
    update = "20m"
  }

  depends_on = [
    helm_release.minio,
    helm_release.rustfs,
    kubernetes_job.rustfs_provision,
  ]
}
