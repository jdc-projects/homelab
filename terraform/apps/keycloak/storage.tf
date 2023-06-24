resource "truenas_dataset" "keycloak_db_dataset" {
  pool               = "vault"
  parent             = "apps"
  name               = "keycloak-db"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = true
  }
}
