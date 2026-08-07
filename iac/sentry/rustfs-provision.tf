locals {
  rustfs_buckets = ["sentry"]
}

resource "kubernetes_job" "rustfs_provision" {
  metadata {
    name      = "rustfs-provision"
    namespace = local.ns
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
              until mc alias set rustfs http://${local.rustfs_svc}:9000 "$$RUSTFS_ACCESS_KEY" "$$RUSTFS_SECRET_KEY"; do
                i=$$((i+1)); [ $$i -ge 60 ] && echo "rustfs not ready, giving up" && exit 1
                echo "waiting for rustfs... ($$i)"; sleep 2
              done
              ${join("\n", [for b in local.rustfs_buckets : "mc mb --ignore-existing rustfs/${b}"])}
            EOT
          ]

          env_from {
            secret_ref { name = kubernetes_secret.sentry_rustfs.metadata[0].name }
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
