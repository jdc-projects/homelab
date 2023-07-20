resource "random_password" "keycloak_client_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "traefik_forward_auth_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}
