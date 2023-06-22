resource "truenas_dataset" "vaultwarden_dataset" {
  pool               = "vault"
  name               = "apps/vaultwarden"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = true
  }
}
