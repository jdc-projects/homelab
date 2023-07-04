resource "random_password" "mariadb_root_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "seafile_keycloak_client_secret" {
  length  = 64
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "seafile_notification_jwt_private_key" {
  length  = 64
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "seafile_admin_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}
