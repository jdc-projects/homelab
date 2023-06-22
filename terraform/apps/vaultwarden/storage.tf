resource "truenas_dataset" "vaultwarden_dataset" {
  pool               = "vault"
  parent             = "apps"
  name               = "vaultwarden"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = true
  }
}
