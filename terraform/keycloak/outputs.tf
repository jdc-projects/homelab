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

output "primary_realm_id" {
  value = keycloak_realm.primary.id
}

output "master_realm_id" {
  value = data.keycloak_realm.master.id
}

output "keycloak_issuer_url" {
  value = "https://${data.terraform_remote_state.prometheus_operator.outputs.oauth_domain}/realms/${data.terraform_remote_state.prometheus_operator.outputs.oauth_realm_name}"
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
