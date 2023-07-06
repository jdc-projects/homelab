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

  standard_flow_enabled        = false
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
    "microprofile-jwt"
  ]
}

resource "keycloak_openid_client_default_scopes" "ocis_web_client_default_scopes" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id = keycloak_openid_client.ocis_web_client.id

  default_scopes = [
    "web-origins",
    "role_list",
    "profile",
    "roles",
    "email"
  ]

  depends_on = [keycloak_openid_client_optional_scopes.ocis_web_client_optional_scopes]
}
