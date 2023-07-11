resource "keycloak_openid_client" "ocis_web" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id = "ocis-web"

  name    = "ocis-web"
  enabled = true

  access_type = "PUBLIC"
  valid_redirect_uris = [
    "https://ocis.${var.server_base_domain}/*",
    "https://files.${var.server_base_domain}/*"
  ]
  web_origins = [
    "https://ocis.${var.server_base_domain}",
    "https://files.${var.server_base_domain}"
  ]

  client_authenticator_type = "client-jwt"

  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  implicit_flow_enabled        = false

  full_scope_allowed = false

  login_theme = "keycloak"
}

resource "keycloak_openid_user_client_role_protocol_mapper" "ocis_web" {
  realm_id                    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id                   = keycloak_openid_client.ocis_web.id
  name                        = "role-mapper"
  claim_name                  = "roles"
  client_id_for_role_mappings = keycloak_openid_client.ocis_web.client_id

  multivalued = "true"

  add_to_id_token     = "false"
  add_to_access_token = "false"
  add_to_userinfo     = "true"
}
