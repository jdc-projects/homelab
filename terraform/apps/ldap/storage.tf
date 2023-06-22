resource "truenas_dataset" "lldap_dataset" {
  pool               = "vault"
  parent             = "apps"
  name               = "lldap"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = true
  }
}
