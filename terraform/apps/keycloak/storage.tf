resource "truenas_dataset" "keycloak_base_dataset" {
  pool               = "vault"
  name               = "keycloak"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = false
  }
}

resource "truenas_dataset" "keycloak_dataset" {
  pool               = "vault"
  parent             = truenas_dataset.keycloak_base_dataset.name
  name               = "keycloak"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = false
  }
}

resource "truenas_dataset" "keycloak_db_dataset" {
  pool               = "vault"
  parent             = truenas_dataset.keycloak_base_dataset.name
  name               = "db"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = false
  }
}
