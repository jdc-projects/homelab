locals {
  keycloak_db_instances = 2
  keycloak_domain       = "idp.${var.server_base_domain}"
}
