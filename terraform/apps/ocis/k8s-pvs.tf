resource "kubernetes_persistent_volume" "ocis_nats_pv" {
  metadata {
    name = "ocis-nats-pv"
  }

  spec {
    capacity = {
      storage = "10Gi"
    }

    access_modes = ["ReadWriteMany"]

    persistent_volume_source {
      host_path {
        path = truenas_dataset.ocis_nats_dataset.mount_point
      }
    }

    storage_class_name = "ocis-nats-host-path"
  }
}

resource "kubernetes_persistent_volume" "ocis_search_pv" {
  metadata {
    name = "ocis-search-pv"
  }

  spec {
    capacity = {
      storage = "10Gi"
    }

    access_modes = ["ReadWriteMany"]

    persistent_volume_source {
      host_path {
        path = truenas_dataset.ocis_search_dataset.mount_point
      }
    }

    storage_class_name = "ocis-search-host-path"
  }
}

resource "kubernetes_persistent_volume" "ocis_storagesystem_pv" {
  metadata {
    name = "ocis-storagesystem-pv"
  }

  spec {
    capacity = {
      storage = "5Gi"
    }

    access_modes = ["ReadWriteMany"]

    persistent_volume_source {
      host_path {
        path = truenas_dataset.ocis_storagesystem_dataset.mount_point
      }
    }

    storage_class_name = "ocis-storagesystem-host-path"
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

    storage_class_name = "ocis-storageusers-host-path"
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

    storage_class_name = "ocis-store-host-path"
  }
}

resource "kubernetes_persistent_volume" "ocis_thumbnails_pv" {
  metadata {
    name = "ocis-thumbnails-pv"
  }

  spec {
    capacity = {
      storage = "10Gi"
    }

    access_modes = ["ReadWriteMany"]

    persistent_volume_source {
      host_path {
        path = truenas_dataset.ocis_thumbnails_dataset.mount_point
      }
    }

    storage_class_name = "ocis-thumbnails-host-path"
  }
}

resource "kubernetes_persistent_volume" "ocis_web_pv" {
  metadata {
    name = "ocis-web-pv"
  }

  spec {
    capacity = {
      storage = "1Gi"
    }

    access_modes = ["ReadWriteMany"]

    persistent_volume_source {
      host_path {
        path = truenas_dataset.ocis_web_dataset.mount_point
      }
    }

    storage_class_name = "ocis-web-host-path"
  }
}
