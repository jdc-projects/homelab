# One-shot provisioning: creates the `data` bucket, grants anonymous download
# on the `public/*` prefix (so browsers read Outline attachments without auth -
# Outline 302-redirects public attachments to a direct S3 URL), and sets bucket
# CORS for browser presigned-POST uploads. This replaces the MinIO chart's
# buckets[]/customCommands[] hooks, which the RustFS chart does not provide.
# Uses mc (RustFS's documented S3 client) since the rustfs binary has no
# bucket/policy subcommands. Idempotent: alias set overwrites, mb uses
# --ignore-existing, anonymous set re-applies the same policy, cors set
# overwrites - safe to re-run.
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
              # Outline uploads via browser presigned POST (cross-origin from the
              # notes host). MinIO enabled permissive CORS by default; RustFS
              # requires explicit PutBucketCors or the browser preflight fails.
              printf '%s' '<CORSConfiguration><CORSRule><AllowedOrigin>https://${local.outline_domain}</AllowedOrigin><AllowedMethod>GET</AllowedMethod><AllowedMethod>PUT</AllowedMethod><AllowedMethod>POST</AllowedMethod><AllowedMethod>HEAD</AllowedMethod><AllowedHeader>*</AllowedHeader><ExposeHeader>ETag</ExposeHeader><ExposeHeader>Content-Disposition</ExposeHeader><MaxAgeSeconds>3000</MaxAgeSeconds></CORSRule></CORSConfiguration>' > /tmp/cors.xml
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
