resource "kubernetes_persistent_volume_claim" "redis" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.grist.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "openebs-zfs-localpv-random-no-backup"

    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = false # *****

    ignore_changes = [spec[0].selector]
  }
}

resource "kubernetes_persistent_volume_claim" "minio" {
  metadata {
    name      = "minio"
    namespace = kubernetes_namespace.grist.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "openebs-zfs-localpv-bulk"

    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = false # *****

    ignore_changes = [spec[0].selector]
  }
}

resource "kubernetes_persistent_volume_claim" "grist" {
  metadata {
    name      = "grist"
    namespace = kubernetes_namespace.grist.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "openebs-zfs-localpv-general"

    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = false # *****

    ignore_changes = [spec[0].selector]
  }
}

resource "kubernetes_persistent_volume_claim" "postgres_debug" {
  metadata {
    name      = "postgres-debug"
    namespace = kubernetes_namespace.grist.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "openebs-zfs-localpv-random"

    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = false # *****

    ignore_changes = [spec[0].selector]
  }
}
