resource "random_password" "keycloak_client_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}
