import {
  to = truenas_dataset.lldap_dataset
  id = "lldap"
}

resource "truenas_dataset" "lldap_dataset" {
  pool               = "vault"
  name               = "lldap"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = true
  }
}
