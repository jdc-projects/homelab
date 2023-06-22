resource "truenas_dataset" "ocis_dataset" {
  pool               = "vault/apps"
  name               = "ocis"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = false
  }
}
