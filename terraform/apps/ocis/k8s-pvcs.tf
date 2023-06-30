resource "kubernetes_persistent_volume_claim" "ocis_nats_pvc" {
  metadata {
    name      = "ocis-nats-pvc"
    namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = kubernetes_persistent_volume.ocis_nats_pv.spec[0].capacity.storage
      }
    }

    storage_class_name = kubernetes_persistent_volume.ocis_nats_pv.spec[0].storage_class_name
  }
}

resource "kubernetes_persistent_volume_claim" "ocis_search_pvc" {
  metadata {
    name      = "ocis-search-pvc"
    namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = kubernetes_persistent_volume.ocis_search_pv.spec[0].capacity.storage
      }
    }

    storage_class_name = kubernetes_persistent_volume.ocis_search_pv.spec[0].storage_class_name
  }
}

resource "kubernetes_persistent_volume_claim" "ocis_storagesystem_pvc" {
  metadata {
    name      = "ocis-storagesystem-pvc"
    namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = kubernetes_persistent_volume.ocis_storagesystem_pv.spec[0].capacity.storage
      }
    }

    storage_class_name = kubernetes_persistent_volume.ocis_storagesystem_pv.spec[0].storage_class_name
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

resource "kubernetes_persistent_volume_claim" "ocis_thumbnails_pvc" {
  metadata {
    name      = "ocis-thumbnails-pvc"
    namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = kubernetes_persistent_volume.ocis_thumbnails_pv.spec[0].capacity.storage
      }
    }

    storage_class_name = kubernetes_persistent_volume.ocis_thumbnails_pv.spec[0].storage_class_name
  }
}

resource "kubernetes_persistent_volume_claim" "ocis_web_pvc" {
  metadata {
    name      = "ocis-web-pvc"
    namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = kubernetes_persistent_volume.ocis_web_pv.spec[0].capacity.storage
      }
    }

    storage_class_name = kubernetes_persistent_volume.ocis_web_pv.spec[0].storage_class_name
  }
}
