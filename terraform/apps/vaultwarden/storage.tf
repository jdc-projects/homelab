resource "truenas_dataset" "vaultwarden_dataset" {
  pool               = "vault"
  name               = "vaultwarden"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = false
  }
}
