resource "random_password" "keycloak_client_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "oauth2_proxy_cookie_secret" {
  length  = 32
  numeric = true
  special = false
  upper   = true
}
