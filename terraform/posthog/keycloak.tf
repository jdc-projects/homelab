resource "random_password" "posthog_oidc_client_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "keycloak_openid_client" "posthog" {
  realm_id  = data.terraform_remote_state.keycloak.outputs.primary_realm_id
  client_id = "posthog"

  name    = "PostHog"
  enabled = true

  access_type = "CONFIDENTIAL"
  valid_redirect_uris = [
    "https://${local.posthog_domain}/complete/saml/"
  ]
  web_origins = [
    "https://${local.posthog_domain}"
  ]

  client_authenticator_type = "client-secret"
  client_secret             = random_password.posthog_oidc_client_secret.result

  standard_flow_enabled        = true
  direct_access_grants_enabled = false
  implicit_flow_enabled        = false

  full_scope_allowed = false

  login_theme = "keycloak"
}
