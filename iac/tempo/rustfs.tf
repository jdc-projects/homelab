locals {
  rustfs_bucket_name = "tempo-traces"
}

# Inline RustFS instance (per-service convention, matching iac/outline
# and iac/posthog). Tempo is cluster-internal, so unlike Outline there is
# no Ingress and the bucket needs no anonymous/CORS setup. The bucket is
# created by kubernetes_job.rustfs_provision (see rustfs-provision.tf), which
# completes before helm_release.tempo installs - so Tempo always starts against
# an existing bucket (no bundled-MinIO-style post-install-hook deadlock).
resource "helm_release" "rustfs" {
  name = "rustfs"

  repository = "https://charts.rustfs.com/"
  chart      = "rustfs"
  version    = "0.9.0"

  namespace = kubernetes_namespace.tempo.metadata[0].name

  timeout = 300

  set = [
    # Pin the fullname so the chart's Service name is deterministic: the chart
    # names its main Service <fullname>-svc, referenced by the provision job
    # and by Tempo's S3 endpoint.
    {
      name  = "fullnameOverride"
      value = "rustfs"
    },
    # Standalone single-node, single-disk.
    {
      name  = "mode.standalone.enabled"
      value = "true"
    },
    {
      name  = "mode.distributed.enabled"
      value = "false"
    },
    {
      name  = "mode.standalone.existingClaim.dataClaim"
      value = kubernetes_persistent_volume_claim.rustfs.metadata[0].name
    },
    # Send logs to stdout; this also skips the chart's separate logs PVC.
    {
      name  = "config.rustfs.obs_log_directory"
      value = ""
    },
    {
      name  = "config.rustfs.region"
      value = "us-east-1"
    },
    # No Ingress - Tempo talks to RustFS over in-cluster DNS.
    {
      name  = "ingress.enabled"
      value = "false"
    },
    # Traces are small; lighter footprint than the outline/posthog RustFS
    # instances which hold user data.
    {
      name  = "resources.requests.cpu"
      value = "100m"
    },
    {
      name  = "resources.requests.memory"
      value = "256Mi"
    },
    {
      name  = "resources.limits.cpu"
      value = "500m"
    },
    {
      name  = "resources.limits.memory"
      value = "512Mi"
    },
  ]

  set_sensitive = [
    {
      name  = "secret.rustfs.access_key"
      value = random_password.rustfs_root_username.result
    },
    {
      name  = "secret.rustfs.secret_key"
      value = random_password.rustfs_root_password.result
    },
  ]
}
