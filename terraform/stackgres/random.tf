resource "random_password" "admin_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}
