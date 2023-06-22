resource "truenas_dataset" "keycloak_db_dataset" {
  pool               = "vault/apps"
  name               = "keycloak-db"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = true
  }
}
