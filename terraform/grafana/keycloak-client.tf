resource "keycloak_openid_client" "grafana" {
  realm_id  = data.terraform_remote_state.keycloak_config.outputs.server_base_domain_realm_id
  client_id = "grafana-old"

  name    = "grafana-old"
  enabled = true

  access_type = "CONFIDENTIAL"
  valid_redirect_uris = [
    "https://grafana.${var.server_base_domain}/*"
  ]
  web_origins = [
    "https://grafana.${var.server_base_domain}"
  ]

  client_authenticator_type = "client-secret"
  client_secret             = random_password.keycloak_client_secret.result

  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  implicit_flow_enabled        = false

  full_scope_allowed = false

  login_theme = "keycloak"
}
