resource "keycloak_openid_client" "openid_client" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.keycloak_lldap_realm_id
  client_id = "ocis-web"

  name    = "ocis-web"
  enabled = true

  access_type = "PUBLIC"
  valid_redirect_uris = [
    "https://ocis.${var.server_base_domain}/*"
  ]

  client_authenticator_type = "client-jwt"

  standard_flow_enabled        = true
  direct_access_grants_enabled = true

  full_scope_allowed = true

  login_theme = "keycloak"

  extra_config = {
    "key1" = "value1"
    "key2" = "value2"
  }
}
