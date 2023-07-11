resource "truenas_dataset" "openldap" {
  pool               = "vault"
  parent             = "apps"
  name               = "openldap"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = true
  }
}
