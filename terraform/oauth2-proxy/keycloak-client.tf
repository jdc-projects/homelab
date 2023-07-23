resource "keycloak_openid_client" "oauth2_proxy" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.server_base_domain_realm_id
  client_id = "oauth2-proxy"

  name    = "oauth2-proxy"
  enabled = true

  access_type = "CONFIDENTIAL"
  valid_redirect_uris = [
    "https://admin.${var.server_base_domain}/*",
    "https://traefik-auth.${var.server_base_domain}/*"
  ]
  web_origins = [
  ]

  client_authenticator_type = "client-secret"
  client_secret             = random_password.keycloak_client_secret.result

  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  implicit_flow_enabled        = true

  full_scope_allowed = false

  login_theme = "keycloak"
}

resource "keycloak_openid_audience_protocol_mapper" "audience_mapper" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.server_base_domain_realm_id
  client_id = keycloak_openid_client.oauth2_proxy.id
  name      = "audience-mapper"

  included_client_audience = keycloak_openid_client.oauth2_proxy.client_id
}
