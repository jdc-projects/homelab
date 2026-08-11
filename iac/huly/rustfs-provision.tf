# One-shot provisioning: creates the `huly` bucket and sets CORS so browsers
# can do cross-origin presigned-POST uploads from the huly.<domain> host.
# Mirrors iac/outline/rustfs-provision.tf. Idempotent (alias set overwrites,
# mb uses --ignore-existing, cors set overwrites - safe to re-run).
resource "kubernetes_job" "rustfs_provision" {
  metadata {
    name      = "rustfs-provision"
    namespace = kubernetes_namespace.huly.metadata[0].name
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
              printf '%s' '<CORSConfiguration><CORSRule><AllowedOrigin>https://${local.huly_domain}</AllowedOrigin><AllowedMethod>GET</AllowedMethod><AllowedMethod>PUT</AllowedMethod><AllowedMethod>POST</AllowedMethod><AllowedMethod>HEAD</AllowedMethod><AllowedHeader>*</AllowedHeader><ExposeHeader>ETag</ExposeHeader><ExposeHeader>Content-Disposition</ExposeHeader><MaxAgeSeconds>3000</MaxAgeSeconds></CORSRule></CORSConfiguration>' > /tmp/cors.xml
              mc cors set rustfs/${local.rustfs_bucket_name} /tmp/cors.xml
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
