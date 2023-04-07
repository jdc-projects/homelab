resource "truenas_dataset" "ocis_dataset" {
  pool               = "vault"
  name               = "ocis"
  inherit_encryption = true

  lifecycle {
    prevent_destroy = false
  }
}
