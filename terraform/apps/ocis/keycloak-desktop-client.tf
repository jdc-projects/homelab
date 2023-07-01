resource "keycloak_openid_client" "ocis_desktop_client" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id = "xdXOt13JKxym1B1QcEncf2XDkLAexMBFwiT9j6EfhhHFJhs2KM9jbjTmf8JBXE69"

  name    = "ocis-desktop"
  enabled = true

  access_type = "CONFIDENTIAL"
  valid_redirect_uris = [
    "http://127.0.0.1:*",
    "http://localhost:*"
  ]

  client_secret = "UBntmLjC2yYCeHwsyj73Uwo9TAaecAetRwMw0xYcvNL9yRdLSUi0hUAHfvCHFeFh"

  client_authenticator_type = "client-secret"

  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  implicit_flow_enabled        = false

  full_scope_allowed = true

  login_theme = "keycloak"
}

resource "keycloak_openid_client_optional_scopes" "ocis_desktop_client_optional_scopes" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id = keycloak_openid_client.ocis_desktop_client.id

  optional_scopes = [
    "address",
    "phone",
    "offline_access",
    "microprofile-jwt"
  ]
}

resource "keycloak_openid_client_default_scopes" "ocis_desktop_client_default_scopes" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id = keycloak_openid_client.ocis_desktop_client.id

  default_scopes = [
    "web-origins",
    "role_list",
    "profile",
    "roles",
    "email"
  ]

  depends_on = [keycloak_openid_client_optional_scopes.ocis_desktop_client_optional_scopes]
}

resource "keycloak_openid_user_client_role_protocol_mapper" "ocis_desktop_client_role_claim_mapper" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id = keycloak_openid_client.ocis_desktop_client.id

  name             = "role-mapper"
  claim_name       = "roles"
  claim_value_type = "String"
  multivalued      = true

  add_to_id_token     = false
  add_to_access_token = false
  add_to_userinfo     = true
}

