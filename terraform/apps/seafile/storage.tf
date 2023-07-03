resource "truenas_dataset" "seafile_base" {
  pool               = "vault"
  parent             = "apps"
  name               = "seafile"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "truenas_dataset" "seafile" {
  pool               = "vault"
  parent             = "apps/seafile"
  name               = "seafile"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [truenas_dataset.seafile_base]
}

resource "truenas_dataset" "mariadb_primary" {
  pool               = "vault"
  parent             = "apps/seafile"
  name               = "mariadb-primary"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [truenas_dataset.seafile_base]
}

resource "kubernetes_persistent_volume" "mariadb_primary" {
  metadata {
    name = "seafile-mariadb-primary"
  }

  spec {
    capacity = {
      storage = "10Gi"
    }

    access_modes = ["ReadWriteMany"]

    persistent_volume_source {
      host_path {
        path = truenas_dataset.mariadb_primary.mount_point
      }
    }

    storage_class_name = "ocis-nats-host-path"
  }
}

resource "kubernetes_persistent_volume_claim" "mariadb_primary" {
  metadata {
    name      = "mariadb-primary"
    namespace = kubernetes_namespace.seafile.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = kubernetes_persistent_volume.mariadb_primary.spec[0].capacity.storage
      }
    }

    storage_class_name = kubernetes_persistent_volume.mariadb_primary.spec[0].storage_class_name
  }
}
