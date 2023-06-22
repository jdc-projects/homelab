resource "truenas_dataset" "lldap_dataset" {
  pool               = "vault/apps"
  name               = "lldap"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = true
  }
}
