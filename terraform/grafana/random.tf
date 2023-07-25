resource "random_password" "admin_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "admin_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}
