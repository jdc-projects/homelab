locals {
  rustfs_bucket_name = "data"
}

# RustFS, deployed alongside MinIO during the transitional phase. The public
# ingress (module "rustfs_ingress") is added in the cutover commit to avoid
# colliding with MinIO on the shared notes-related hostname; until then RustFS
# is reachable only in-cluster at rustfs-svc:9000 (used by the migrate job).
resource "helm_release" "rustfs" {
  name = "rustfs"

  repository = "https://charts.rustfs.com/"
  chart      = "rustfs"
  version    = "0.9.0"

  namespace = kubernetes_namespace.outline.metadata[0].name

  timeout = 300

  set = [
    # Pin the fullname so the chart's Service name is deterministic: the chart
    # names its main Service <fullname>-svc, referenced by the migrate job.
    {
      name  = "fullnameOverride"
      value = "rustfs"
    },
    # Standalone single-node, single-disk - matches the previous MinIO topology.
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
    # Matches Outline's AWS_REGION.
    {
      name  = "config.rustfs.region"
      value = "us-east-1"
    },
    # RustFS is reached in-cluster during the transitional phase, so disable the
    # chart's own ingress (the shared Traefik ingress is wired up at cutover).
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
