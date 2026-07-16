# One-shot provisioning: creates the `data` bucket and grants anonymous download
# on the `public/*` prefix so browsers can read Outline attachments without auth
# (Outline 302-redirects public attachments to a direct S3 URL). This replaces
# the MinIO chart's buckets[]/customCommands[] hooks, which the RustFS chart does
# not provide. Uses mc (RustFS's documented S3 client) since the rustfs binary
# has no bucket/policy subcommands. Idempotent: alias set overwrites, mb uses
# --ignore-existing, anonymous set re-applies the same policy - safe to re-run.
resource "kubernetes_job" "rustfs_provision" {
  metadata {
    name      = "rustfs-provision"
    namespace = kubernetes_namespace.outline.metadata[0].name
  }

  spec {
    template {
      metadata {}

      spec {
        restart_policy = "Never"

        container {
          image = "minio/mc:RELEASE.2025-08-13T08-35-41Z"
          name  = "rustfs-provision"

          command = [
            "/bin/sh",
            "-c",
            <<-EOT
              i=0
              until mc alias set rustfs http://rustfs-svc:9000 "$RUSTFS_ACCESS_KEY" "$RUSTFS_SECRET_KEY"; do
                i=$((i+1)); [ $i -ge 60 ] && echo "rustfs not ready, giving up" && exit 1
                echo "waiting for rustfs... ($i)"; sleep 2
              done
              mc mb --ignore-existing rustfs/${local.rustfs_bucket_name}
              mc anonymous set download rustfs/${local.rustfs_bucket_name}/public/*
            EOT
          ]

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
    create = "5m"
    update = "5m"
  }

  depends_on = [helm_release.rustfs]
}
