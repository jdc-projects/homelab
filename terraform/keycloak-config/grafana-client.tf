resource "keycloak_openid_client" "grafana" {
  realm_id  = keycloak_realm.primary.id
  client_id = data.terraform_remote_state.prometheus_operator.outputs.grafana_oauth_client_id

  name    = data.terraform_remote_state.prometheus_operator.outputs.grafana_oauth_client_id
  enabled = true

  access_type = "CONFIDENTIAL"
  valid_redirect_uris = [
    "${data.terraform_remote_state.prometheus_operator.outputs.grafana_url}/*"
  ]
  web_origins = [
    data.terraform_remote_state.prometheus_operator.outputs.grafana_url
  ]

  client_authenticator_type = "client-secret"
  client_secret             = data.terraform_remote_state.prometheus_operator.outputs.grafana_oauth_client_secret

  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  implicit_flow_enabled        = false

  full_scope_allowed = false

  login_theme = "keycloak"
}
