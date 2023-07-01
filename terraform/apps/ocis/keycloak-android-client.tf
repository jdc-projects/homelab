resource "keycloak_openid_client" "ocis_android_client" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id = "e4rAsNUSIUs0lF4nbv9FmCeUkTlV9GdgTLDH1b5uie7syb90SzEVrbN7HIpmWJeD"

  name    = "ocis-android"
  enabled = true

  access_type = "CONFIDENTIAL"
  valid_redirect_uris = [
    "oc://android.owncloud.com"
  ]

  client_secret = "dInFYGV33xKzhbRmpqQltYNdfLdJIfJ9L5ISoKhNoT9qZftpdWSP71VrpGR9pmoD"

  client_authenticator_type = "client-secret"

  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  implicit_flow_enabled        = false

  full_scope_allowed = true

  login_theme = "keycloak"
}

resource "keycloak_openid_client_optional_scopes" "ocis_android_client_optional_scopes" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id = keycloak_openid_client.ocis_android_client.id

  optional_scopes = [
    "address",
    "phone",
    "offline_access",
    "microprofile-jwt"
  ]
}

resource "keycloak_openid_client_default_scopes" "ocis_android_client_default_scopes" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id = keycloak_openid_client.ocis_android_client.id

  default_scopes = [
    "web-origins",
    "role_list",
    "profile",
    "roles",
    "email"
  ]

  depends_on = [keycloak_openid_client_optional_scopes.ocis_android_client_optional_scopes]
}

resource "keycloak_openid_user_client_role_protocol_mapper" "ocis_android_client_role_claim_mapper" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id = keycloak_openid_client.ocis_android_client.id

  name             = "role-mapper"
  claim_name       = "roles"
  claim_value_type = "String"
  multivalued      = true

  add_to_id_token     = false
  add_to_access_token = false
  add_to_userinfo     = true
}

