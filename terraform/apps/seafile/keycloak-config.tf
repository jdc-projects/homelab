resource "keycloak_openid_client" "seafile" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id = "seafile"

  name    = "seafile"
  enabled = true

  access_type = "CONFIDENTIAL"
  valid_redirect_uris = [
    "https://seafile.${var.server_base_domain}/oauth/callback/"
  ]

  client_secret = random_password.seafile_keycloak_client_secret.result

  client_authenticator_type = "client-secret"

  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  implicit_flow_enabled        = false

  full_scope_allowed = false

  login_theme = "keycloak"
}

# ***** custom mapper setup
resource "keycloak_generic_protocol_mapper" "user_domain_claim" {
  realm_id        = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  name            = "username-realm-mapper"
  protocol        = "openid-connect"
  protocol_mapper = "username-realm-mapper.js"
  client_id       = keycloak_openid_client.seafile.claim_id
  config = {
  }
}
