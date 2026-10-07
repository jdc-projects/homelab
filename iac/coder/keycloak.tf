resource "keycloak_openid_client" "coder" {
  realm_id  = data.terraform_remote_state.keycloak.outputs.primary_realm_id
  client_id = "coder"

  name    = "Coder"
  enabled = true

  access_type = "CONFIDENTIAL"
  # Coder's OIDC callback path (differs from the usual /oidc/callback).
  valid_redirect_uris = [
    "https://${local.coder_domain}/api/v2/users/oidc/callback",
  ]
  web_origins = [
    "https://${local.coder_domain}",
  ]

  client_authenticator_type = "client-secret"
  client_secret             = random_password.keycloak_client_secret.result

  standard_flow_enabled        = true
  direct_access_grants_enabled = false
  implicit_flow_enabled        = false

  full_scope_allowed = false

  login_theme = "keycloak"
}
