resource "truenas_dataset" "ocis_base_dataset" {
  pool               = "vault"
  parent             = "apps"
  name               = "ocis"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = false
  }
}

resource "truenas_dataset" "ocis_storageusers_dataset" {
  pool               = "vault/apps"
  parent             = "ocis"
  name               = "storageusers"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = false
  }
}

resource "truenas_dataset" "ocis_store_dataset" {
  pool               = "vault/apps"
  parent             = "ocis"
  name               = "store"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = false
  }
}

resource "kubernetes_persistent_volume" "ocis_storageusers_pv" {
  metadata {
    name = "ocis-storageusers-pv"
  }

  spec {
    capacity = {
      storage = "50Gi"
    }

    access_modes = ["ReadWriteMany"]

    persistent_volume_source {
      host_path {
        path = truenas_dataset.ocis_storageusers_dataset.mount_point
      }
    }

    storage_class_name = "ocis_host_path"
  }
}

resource "kubernetes_persistent_volume_claim" "ocis_storageusers_pvc" {
  metadata {
    name      = "ocis-storageusers-pvc"
    namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = kubernetes_persistent_volume.ocis_storageusers_pv.spec[0].capacity.storage
      }
    }

    storage_class_name = kubernetes_persistent_volume.ocis_storageusers_pv.spec[0].storage_class_name
  }
}

resource "kubernetes_persistent_volume" "ocis_store_pv" {
  metadata {
    name = "ocis-store-pv"
  }

  spec {
    capacity = {
      storage = "5Gi"
    }

    access_modes = ["ReadWriteMany"]

    persistent_volume_source {
      host_path {
        path = truenas_dataset.ocis_store_dataset.mount_point
      }
    }

    storage_class_name = "ocis_host_path"
  }
}

resource "kubernetes_persistent_volume_claim" "ocis_store_pvc" {
  metadata {
    name      = "ocis-store-pvc"
    namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = kubernetes_persistent_volume.ocis_store_pv.spec[0].capacity.storage
      }
    }

    storage_class_name = kubernetes_persistent_volume.ocis_store_pv.spec[0].storage_class_name
  }
}
