resource "kubernetes_namespace" "kubevirt_images" {
  metadata {
    name = "kubevirt-images"
  }
}

resource "kubernetes_persistent_volume_claim" "opnsense" {
  for_each = tomap({
    opnsense-24-7-nano-amd64 = tomap({
      storage            = "4Gi"
      storage_class_name = "openebs-zfs-localpv-bulk-no-backup"
      endpoint           = "https://www.mirrorservice.org/sites/opnsense.org/releases/24.7/OPNsense-24.7-nano-amd64.img.bz2"
    })
    fedora-cloud-base-generic-41-1-4-x86-64 = tomap({
      storage            = "6Gi"
      storage_class_name = "openebs-zfs-localpv-bulk-no-backup"
      endpoint           = "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2"
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
