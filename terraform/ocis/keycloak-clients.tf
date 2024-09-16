resource "keycloak_openid_client" "ocis_web" {
  realm_id  = data.terraform_remote_state.keycloak.outputs.primary_realm_id
  client_id = "ocis-web"

  name    = "ocis-web"
  enabled = true

  access_type = "PUBLIC"
  valid_redirect_uris = [
    "https://${local.ocis_domain}/*"
  ]
  web_origins = [
    "https://${local.ocis_domain}"
  ]

  client_authenticator_type = "client-jwt"

  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  implicit_flow_enabled        = false

  full_scope_allowed = false

  login_theme = "keycloak"
}

resource "keycloak_openid_client" "ocis_desktop" {
  realm_id  = data.terraform_remote_state.keycloak.outputs.primary_realm_id
  client_id = "xdXOt13JKxym1B1QcEncf2XDkLAexMBFwiT9j6EfhhHFJhs2KM9jbjTmf8JBXE69"

  name    = "ocis-desktop"
  enabled = true

  access_type = "PUBLIC"
  valid_redirect_uris = [
    "http://127.0.0.1:*",
    "http://localhost:*"
  ]

  client_authenticator_type = "client-jwt"

  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  implicit_flow_enabled        = false

  full_scope_allowed = false

  login_theme = "keycloak"
}

resource "keycloak_openid_client" "ocis_android" {
  realm_id  = data.terraform_remote_state.keycloak.outputs.primary_realm_id
  client_id = "e4rAsNUSIUs0lF4nbv9FmCeUkTlV9GdgTLDH1b5uie7syb90SzEVrbN7HIpmWJeD"

  name    = "ocis-android"
  enabled = true

  access_type = "PUBLIC"
  valid_redirect_uris = [
    "oc://android.owncloud.com"
  ]

  client_authenticator_type = "client-jwt"

  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  implicit_flow_enabled        = false

  full_scope_allowed = false

  login_theme = "keycloak"
}

resource "keycloak_openid_client" "ocis_ios" {
  realm_id  = data.terraform_remote_state.keycloak.outputs.primary_realm_id
  client_id = "mxd5OQDk6es5LzOzRvidJNfXLUZS2oN3oUFeXPP8LpPrhx3UroJFduGEYIBOxkY1"

  name    = "ocis-ios"
  enabled = true

  access_type = "PUBLIC"
  valid_redirect_uris = [
    "oc://ios.owncloud.com"
  ]

  client_authenticator_type = "client-jwt"

  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  implicit_flow_enabled        = false

  full_scope_allowed = false

  login_theme = "keycloak"
}
