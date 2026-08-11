resource "keycloak_openid_client" "huly" {
  realm_id  = data.terraform_remote_state.keycloak.outputs.primary_realm_id
  client_id = "huly"

  name    = "huly"
  enabled = true

  access_type = "CONFIDENTIAL"
  valid_redirect_uris = [
    "https://${local.huly_domain}/_accounts/auth/openid/callback"
  ]
  web_origins = [
    "https://${local.huly_domain}"
  ]

  client_authenticator_type = "client-secret"
  client_secret             = random_password.keycloak_client_secret.result

  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  implicit_flow_enabled        = false

  full_scope_allowed = false

  login_theme = "keycloak"
}
