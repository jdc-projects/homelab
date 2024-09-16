resource "random_password" "keycloak_client_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "grafana_admin_password" {
  length  = 32
  numeric = true
  special = false
  upper   = true
}
