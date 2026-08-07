# Sentry application OIDC client (Keycloak). This is the app's own SSO via the
# sentry-auth-oidc plugin — distinct from anything the ingress module manages.
# The plugin's redirect endpoint is /auth/sso/ (per sentry-auth-oidc docs).
resource "random_password" "sentry_oidc_client_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "keycloak_openid_client" "sentry" {
  realm_id  = data.terraform_remote_state.keycloak.outputs.primary_realm_id
  client_id = "sentry"

  name    = "Sentry"
  enabled = true

  access_type = "CONFIDENTIAL"
  valid_redirect_uris = [
    "https://${local.sentry_domain}/auth/sso/",
  ]
  web_origins = [
    "https://${local.sentry_domain}"
  ]

  client_authenticator_type = "client-secret"
  client_secret             = random_password.sentry_oidc_client_secret.result

  standard_flow_enabled        = true
  direct_access_grants_enabled = false
  implicit_flow_enabled        = false

  full_scope_allowed = false

  login_theme = "keycloak"
}
