resource "random_password" "keycloak_client_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "docker_hub_reader_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}
