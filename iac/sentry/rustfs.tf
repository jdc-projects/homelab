locals {
  rustfs_svc = "rustfs-svc"
}

resource "kubernetes_persistent_volume_claim" "rustfs" {
  metadata {
    name      = "rustfs"
    namespace = local.ns
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "openebs-zfs-localpv-bulk-no-backup"

    resources {
      requests = {
        storage = "20Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [spec[0].selector]
  }
}

resource "helm_release" "rustfs" {
  name       = "rustfs"
  repository = "https://charts.rustfs.com/"
  chart      = "rustfs"
  version    = local.rustfs_chart_version

  namespace = local.ns

  timeout = 300

  set = [
    { name = "fullnameOverride", value = "rustfs" },
    { name = "mode.standalone.enabled", value = "true" },
    { name = "mode.distributed.enabled", value = "false" },
    { name = "mode.standalone.existingClaim.dataClaim", value = kubernetes_persistent_volume_claim.rustfs.metadata[0].name },
    { name = "config.rustfs.obs_log_directory", value = "" },
    { name = "config.rustfs.region", value = "us-east-1" },
    { name = "ingress.enabled", value = "false" },
    { name = "resources.requests.cpu", value = "100m" },
    { name = "resources.requests.memory", value = "512Mi" },
    { name = "resources.limits.cpu", value = "2000m" },
    { name = "resources.limits.memory", value = "1Gi" },
  ]

  set_sensitive = [
    { name = "secret.rustfs.access_key", value = random_password.rustfs_username.result },
    { name = "secret.rustfs.secret_key", value = random_password.rustfs_password.result },
  ]
}
