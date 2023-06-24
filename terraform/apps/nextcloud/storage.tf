resource "truenas_dataset" "nextcloud_dataset" {
  pool               = "vault"
  name               = "nextcloud"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = false
  }
}
