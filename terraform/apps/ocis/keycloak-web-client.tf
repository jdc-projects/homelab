resource "keycloak_openid_client" "ocis_web_client" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id = "ocis-web"

  name    = "ocis-web"
  enabled = true

  access_type = "PUBLIC"
  valid_redirect_uris = [
    "https://ocis.${var.server_base_domain}/*"
  ]
  web_origins = [
    "https://ocis.${var.server_base_domain}"
  ]

  client_authenticator_type = "client-jwt"

  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  implicit_flow_enabled        = true

  full_scope_allowed = true

  login_theme = "keycloak"
}

resource "keycloak_openid_client_optional_scopes" "ocis_web_client_optional_scopes" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id = keycloak_openid_client.ocis_web_client.id

  optional_scopes = [
    "address",
    "phone",
    "offline_access",
  ]
}

resource "keycloak_openid_client_default_scopes" "ocis_web_client_default_scopes" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id = keycloak_openid_client.ocis_web_client.id

  default_scopes = [
    "acr",
    "email",
    "microprofile-jwt",
    "profile",
    "roles",
    "web-origins",
  ]

  depends_on = [keycloak_openid_client_optional_scopes.ocis_web_client_optional_scopes]
}

resource "keycloak_openid_user_client_role_protocol_mapper" "ocis_web_client_role_claim_mapper" {
  realm_id                    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id                   = keycloak_openid_client.ocis_web_client.id
  client_id_for_role_mappings = keycloak_openid_client.ocis_web_client.client_id

  name             = "role-mapper"
  claim_name       = "roles"
  claim_value_type = "String"
  multivalued      = true

  add_to_id_token     = false
  add_to_access_token = false
  add_to_userinfo     = true
}
