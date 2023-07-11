resource "truenas_dataset" "ocis_base_dataset" {
  pool               = "vault"
  parent             = "apps"
  name               = "ocis"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = false
  }
}

resource "truenas_dataset" "ocis_nats_dataset" {
  pool               = "vault"
  parent             = "apps/ocis"
  name               = "nats"
  inherit_encryption = true

  depends_on = [truenas_dataset.ocis_base_dataset]

  lifecycle {
    prevent_destroy = false
  }
}

resource "truenas_dataset" "ocis_search_dataset" {
  pool               = "vault"
  parent             = "apps/ocis"
  name               = "search"
  inherit_encryption = true

  depends_on = [truenas_dataset.ocis_base_dataset]

  lifecycle {
    prevent_destroy = false
  }
}

resource "truenas_dataset" "ocis_storagesystem_dataset" {
  pool               = "vault"
  parent             = "apps/ocis"
  name               = "storagesystem"
  inherit_encryption = true

  depends_on = [truenas_dataset.ocis_base_dataset]

  lifecycle {
    prevent_destroy = false
  }
}

resource "truenas_dataset" "ocis_storageusers_dataset" {
  pool               = "vault"
  parent             = "apps/ocis"
  name               = "storageusers"
  inherit_encryption = true

  depends_on = [truenas_dataset.ocis_base_dataset]

  lifecycle {
    prevent_destroy = false
  }
}

resource "truenas_dataset" "ocis_store_dataset" {
  pool               = "vault"
  parent             = "apps/ocis"
  name               = "store"
  inherit_encryption = true

  depends_on = [truenas_dataset.ocis_base_dataset]

  lifecycle {
    prevent_destroy = false
  }
}

resource "truenas_dataset" "ocis_thumbnails_dataset" {
  pool               = "vault"
  parent             = "apps/ocis"
  name               = "thumbnails"
  inherit_encryption = true

  depends_on = [truenas_dataset.ocis_base_dataset]

  lifecycle {
    prevent_destroy = false
  }
}

resource "truenas_dataset" "ocis_web_dataset" {
  pool               = "vault"
  parent             = "apps/ocis"
  name               = "web"
  inherit_encryption = true

  depends_on = [truenas_dataset.ocis_base_dataset]

  lifecycle {
    prevent_destroy = false
  }
}
