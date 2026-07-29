locals {
  rustfs_svc     = "rustfs-svc"
  rustfs_rec_svc = "rustfs-recordings-svc"
}

resource "kubernetes_persistent_volume_claim" "rustfs" {
  metadata {
    name      = "rustfs"
    namespace = kubernetes_namespace.posthog.metadata[0].name
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
    ignore_changes  = [spec[0].selector]
  }
}

resource "helm_release" "rustfs" {
  name       = "rustfs"
  repository = "https://charts.rustfs.com/"
  chart      = "rustfs"
  version    = local.rustfs_chart_version

  namespace = kubernetes_namespace.posthog.metadata[0].name

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
    { name = "resources.limits.cpu", value = "500m" },
    { name = "resources.limits.memory", value = "1Gi" },
  ]

  set_sensitive = [
    { name = "secret.rustfs.access_key", value = random_password.rustfs_primary_username.result },
    { name = "secret.rustfs.secret_key", value = random_password.rustfs_primary_password.result },
  ]
}

resource "kubernetes_persistent_volume_claim" "rustfs_recordings" {
  metadata {
    name      = "rustfs-recordings"
    namespace = kubernetes_namespace.posthog.metadata[0].name
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
    ignore_changes  = [spec[0].selector]
  }
}

resource "helm_release" "rustfs_recordings" {
  name       = "rustfs-recordings"
  repository = "https://charts.rustfs.com/"
  chart      = "rustfs"
  version    = local.rustfs_chart_version

  namespace = kubernetes_namespace.posthog.metadata[0].name

  timeout = 300

  set = [
    { name = "fullnameOverride", value = "rustfs-recordings" },
    { name = "mode.standalone.enabled", value = "true" },
    { name = "mode.distributed.enabled", value = "false" },
    { name = "mode.standalone.existingClaim.dataClaim", value = kubernetes_persistent_volume_claim.rustfs_recordings.metadata[0].name },
    { name = "config.rustfs.obs_log_directory", value = "" },
    { name = "config.rustfs.region", value = "us-east-1" },
    { name = "ingress.enabled", value = "false" },
    { name = "resources.requests.cpu", value = "100m" },
    { name = "resources.requests.memory", value = "512Mi" },
    { name = "resources.limits.cpu", value = "500m" },
    { name = "resources.limits.memory", value = "1Gi" },
  ]

  set_sensitive = [
    { name = "secret.rustfs.access_key", value = random_password.rustfs_recordings_username.result },
    { name = "secret.rustfs.secret_key", value = random_password.rustfs_recordings_password.result },
  ]
}
