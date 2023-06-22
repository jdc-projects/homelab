resource "truenas_dataset" "vaultwarden_dataset" {
  pool               = "vault/apps"
  name               = "vaultwarden"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = true
  }
}
