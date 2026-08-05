locals {
  primary_buckets   = ["posthog", "ducklake-dev", "ai-blobs"]
  recordings_bucket = "posthog"
}

resource "kubernetes_job" "rustfs_provision" {
  metadata {
    name      = "rustfs-provision"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  spec {
    template {
      metadata {}

      spec {
        restart_policy = "Never"

        container {
          image = local.minio_mc_image
          name  = "rustfs-provision"

          command = [
            "/bin/sh",
            "-c",
            <<-EOT
              i=0
              until mc alias set rustfs http://${local.rustfs_svc}:9000 "$RUSTFS_ACCESS_KEY" "$RUSTFS_SECRET_KEY"; do
                i=$$((i+1)); [ $$i -ge 60 ] && echo "rustfs not ready, giving up" && exit 1
                echo "waiting for rustfs... ($$i)"; sleep 2
              done
              ${join("\n", [for b in local.primary_buckets : "mc mb --ignore-existing rustfs/${b}"])}
            EOT
          ]

          env_from {
            secret_ref { name = kubernetes_secret.rustfs_provision_secrets.metadata[0].name }
          }
        }
      }
    }

    backoff_limit              = 0
    ttl_seconds_after_finished = 86400
  }

  wait_for_completion = true

  timeouts {
    create = "5m"
    update = "5m"
  }

  depends_on = [helm_release.rustfs]
}

resource "kubernetes_job" "rustfs_recordings_provision" {
  metadata {
    name      = "rustfs-recordings-provision"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  spec {
    template {
      metadata {}

      spec {
        restart_policy = "Never"

        container {
          image = local.minio_mc_image
          name  = "rustfs-recordings-provision"

          command = [
            "/bin/sh",
            "-c",
            <<-EOT
              i=0
              until mc alias set rustfs http://${local.rustfs_rec_svc}:9000 "$RUSTFS_ACCESS_KEY" "$RUSTFS_SECRET_KEY"; do
                i=$$((i+1)); [ $$i -ge 60 ] && echo "rustfs not ready, giving up" && exit 1
                echo "waiting for rustfs-recordings... ($$i)"; sleep 2
              done
              mc mb --ignore-existing rustfs/${local.recordings_bucket}
            EOT
          ]

          env_from {
            secret_ref { name = kubernetes_secret.rustfs_recordings_provision_secrets.metadata[0].name }
          }
        }
      }
    }

    backoff_limit              = 0
    ttl_seconds_after_finished = 86400
  }

  wait_for_completion = true

  timeouts {
    create = "5m"
    update = "5m"
  }

  depends_on = [helm_release.rustfs_recordings]
}
