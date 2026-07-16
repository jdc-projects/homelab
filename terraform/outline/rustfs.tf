locals {
  rustfs_bucket_name = "data"
  # Renamed from MinIO's `minio-notes.<base>` to `assets-notes.<base>`. Safe
  # because Outline stores only the attachment id in document bodies and resolves
  # the S3 host from this env at view-time. Covered by the *.<base> wildcard cert.
  rustfs_domain = "assets-notes.${var.server_base_domain}"
}

# RustFS, the MinIO replacement. Outline uploads server-side over the public
# assets-notes hostname (Traefik terminates TLS via the *.<base> wildcard cert);
# browsers read public attachments directly from the same host.
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
    # Disable the chart's own ingress; RustFS is exposed via the shared Traefik
    # IngressRoute module (rustfs_ingress below).
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

module "rustfs_ingress" {
  source = "../modules/ingress"

  name      = "rustfs"
  namespace = kubernetes_namespace.outline.metadata[0].name
  domain    = local.rustfs_domain

  target_port = 9000

  existing_service_name      = "rustfs-svc" # fullnameOverride + chart's "-svc" suffix
  existing_service_namespace = helm_release.rustfs.namespace
}
