resource "random_password" "keycloak_client_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

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
