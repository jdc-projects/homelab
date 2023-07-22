resource "keycloak_openid_client" "traefik_forward_auth" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.server_base_domain_realm_id
  client_id = "traefik-forward-auth"

  name    = "traefik-forward-auth"
  enabled = true

  access_type = "CONFIDENTIAL"
  valid_redirect_uris = [
    "https://admin.${var.server_base_domain}/*"
  ]
  web_origins = [
  ]

  client_authenticator_type = "client-secret"
  client_secret             = random_password.keycloak_client_secret.result

  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  implicit_flow_enabled        = false

  full_scope_allowed = false

  login_theme = "keycloak"
}
