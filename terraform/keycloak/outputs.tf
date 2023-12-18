output "keycloak_admin_username" {
  value     = random_password.keycloak_admin_username.result
  sensitive = true
}

output "keycloak_admin_password" {
  value     = random_password.keycloak_admin_password.result
  sensitive = true
}

output "keycloak_url" {
  value = "https://${data.terraform_remote_state.prometheus_operator.outputs.oauth_domain}"
}

output "grafana_keycloak_client_id" {
  value = data.terraform_remote_state.prometheus_operator.outputs.grafana_oauth_client_id
}

output "grafana_keycloak_client_secret" {
  value = data.terraform_remote_state.prometheus_operator.outputs.grafana_oauth_client_secret
  sensitive = true
}

output "keycloak_realm_name" {
  value = data.terraform_remote_state.prometheus_operator.outputs.keycloak_realm_name
}

output "keycloak_url_base" {
  value = data.terraform_remote_state.prometheus_operator.outputs.oauth_url_base
}

output "keycloak_auth_url" {
  value = data.terraform_remote_state.prometheus_operator.outputs.oauth_auth_url
}

output "keycloak_token_url" {
  value = data.terraform_remote_state.prometheus_operator.outputs.oauth_token_url
}

output "keycloak_api_url" {
  value = data.terraform_remote_state.prometheus_operator.outputs.oauth_api_url
}

output "grafana_keycloak_admin_role_name" {
  value = data.terraform_remote_state.prometheus_operator.outputs.grafana_oauth_admin_role_name
}
