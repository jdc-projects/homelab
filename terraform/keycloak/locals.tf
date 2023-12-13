locals {
  keycloak_db_replicas = 2
  keycloak_domain      = "idp.${var.server_base_domain}"
}
