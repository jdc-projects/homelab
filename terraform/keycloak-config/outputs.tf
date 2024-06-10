output "keycloak_admin_username" {
  value     = data.terraform_remote_state.keycloak.outputs.keycloak_admin_username
  sensitive = true
}

output "keycloak_admin_password" {
  value     = data.terraform_remote_state.keycloak.outputs.keycloak_admin_password
  sensitive = true
}

output "keycloak_url" {
  value = data.terraform_remote_state.keycloak.outputs.keycloak_url
}

output "primary_realm_id" {
  value = keycloak_realm.primary.id
}

output "keycloak_base_url" {
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
