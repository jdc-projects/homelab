resource "truenas_dataset" "apps_dataset" {
  pool               = "vault"
  name               = "apps"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = true
  }
}
