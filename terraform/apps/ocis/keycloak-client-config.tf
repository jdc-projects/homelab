resource "null_resource" "ocis_keycloak_client_id" {
  triggers = {
    client_id = "ocis"
  }
}

resource "keycloak_openid_client" "ocis_web_client" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.keycloak_lldap_realm_id
  client_id = null_resource.ocis_keycloak_client_id.triggers.client_id

  name    = null_resource.ocis_keycloak_client_id.triggers.client_id
  enabled = true

  access_type = "PUBLIC"
  valid_redirect_uris = [
    "https://${null_resource.ocis_keycloak_client_id.triggers.client_id}.${var.server_base_domain}/*"
  ]
  web_origins = [
    "https://${null_resource.ocis_keycloak_client_id.triggers.client_id}.${var.server_base_domain}"
  ]

  client_authenticator_type = "client-jwt"

  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  implicit_flow_enabled        = true

  full_scope_allowed = true

  login_theme = "base"
}
