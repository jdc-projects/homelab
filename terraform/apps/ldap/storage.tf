resource "truenas_dataset" "lldap_dataset" {
  pool               = "vault"
  name               = "apps/lldap"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = true
  }
}
