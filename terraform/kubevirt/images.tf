resource "kubernetes_namespace" "kubevirt_images" {
  metadata {
    name = "kubevirt-images"
  }
}

resource "kubernetes_persistent_volume_claim" "opnsense" {
  for_each = tomap({
    ubuntu-noble-server-cloudimg-amd64 = tomap({
      storage            = "4Gi"
      storage_class_name = "openebs-zfs-localpv-bulk-no-backup"
      endpoint           = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    })
  })

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.kubevirt_images.metadata[0].name

    labels = {
      app = "containerized-data-importer"
    }

    annotations = {
      "cdi.kubevirt.io/storage.import.endpoint" = each.value.endpoint
    }
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = each.value.storage_class_name

    resources {
      requests = {
        storage = each.value.storage
      }
    }
  }

  lifecycle {
    prevent_destroy = false

    ignore_changes = [
      metadata[0].annotations,
      spec[0].selector,
    ]
  }
}
