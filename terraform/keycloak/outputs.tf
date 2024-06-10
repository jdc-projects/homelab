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

output "keycloak_realm_name" {
  value = data.terraform_remote_state.prometheus_operator.outputs.oauth_realm_name
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

output "keycloak_logout_url" {
  value = data.terraform_remote_state.prometheus_operator.outputs.oauth_logout_url
}
