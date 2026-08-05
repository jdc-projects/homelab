# One-shot provisioning: creates the `tempo-traces` bucket before the Tempo
# helm release installs. Uses mc (RustFS's documented S3 client) since the
# rustfs binary has no bucket subcommands. Idempotent: alias set overwrites and
# mb uses --ignore-existing, so safe to re-run. Mirrors
# terraform/outline/rustfs-provision.tf (minus the anonymous/CORS steps, which
# Tempo - being cluster-internal - does not need).
resource "kubernetes_job" "rustfs_provision" {
  metadata {
    name      = "rustfs-provision"
    namespace = kubernetes_namespace.tempo.metadata[0].name
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
