resource "random_password" "keycloak_client_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "docker_hub_reader_password" {
  length  = 20
  numeric = true
  special = false
  upper   = true
}
