resource "random_password" "keycloak_admin_username" {
  length  = 16
  numeric = false
  special = false
}

resource "random_password" "keycloak_admin_password" {
  length  = 16
  numeric = true
  special = false
}

resource "random_password" "db_admin_username" {
  length  = 16
  numeric = false
  special = false
}

resource "random_password" "db_admin_password" {
  length  = 16
  numeric = true
  special = false
}
