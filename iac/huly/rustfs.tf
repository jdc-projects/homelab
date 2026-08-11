locals {
  rustfs_bucket_name = "huly"
  # Exposed publicly so browsers can read attachment URLs Huly embeds in
  # documents. Covered by the *.<base> wildcard cert.
  rustfs_domain = "assets-huly.${var.server_base_domain}"
}

# RustFS - MinIO replacement. Huly uploads over the in-cluster rustfs-svc
# hostname; browsers read public attachments from the public assets-huly
# host (Traefik terminates TLS via the *.<base> wildcard cert).
resource "kubernetes_persistent_volume_claim" "rustfs" {
  metadata {
    name      = "rustfs"
    namespace = kubernetes_namespace.huly.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "openebs-zfs-localpv-bulk"

    resources {
      requests = {
        storage = "20Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [spec[0].selector]
  }
}

resource "helm_release" "rustfs" {
  name = "rustfs"

  repository = "https://charts.rustfs.com/"
  chart      = "rustfs"
  version    = "0.9.0"

  namespace = kubernetes_namespace.huly.metadata[0].name

  timeout = 300

  set = [
    # Pin the fullname so the chart's Service name is deterministic. The chart
    # names its main Service <fullname>-svc, referenced by this name in
    # storage_config below and by the migrate job.
    {
      name  = "fullnameOverride"
      value = "rustfs"
    },
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
    {
      name  = "config.rustfs.obs_log_directory"
      value = ""
    },
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
  namespace = kubernetes_namespace.huly.metadata[0].name
  domain    = local.rustfs_domain

  target_port = 9000

  existing_service_name      = "rustfs-svc" # fullnameOverride + chart's "-svc" suffix
  existing_service_namespace = helm_release.rustfs.namespace
}
