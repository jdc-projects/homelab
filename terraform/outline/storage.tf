resource "kubernetes_persistent_volume_claim" "redis" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.outline.metadata[0].name
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
    prevent_destroy = true

    ignore_changes = [spec[0].selector]
  }
}

resource "kubernetes_persistent_volume_claim" "minio" {
  metadata {
    name      = "minio"
    namespace = kubernetes_namespace.outline.metadata[0].name
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
    prevent_destroy = true

    ignore_changes = [spec[0].selector]
  }
}

# resource "kubernetes_persistent_volume_claim" "outline" {
#   metadata {
#     name      = "outline"
#     namespace = kubernetes_namespace.outline.metadata[0].name
#   }

#   spec {
#     access_modes       = ["ReadWriteOnce"]
#     storage_class_name = "openebs-zfs-localpv-bulk"

#     resources {
#       requests = {
#         storage = "10Gi"
#       }
#     }
#   }

#   lifecycle {
#     prevent_destroy = true

#     ignore_changes = [spec[0].selector]
#   }
# }
