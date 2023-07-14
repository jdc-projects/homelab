output "keycloak_admin_username" {
  value     = data.terraform_remote_state.keycloak.outputs.keycloak_admin_username
  sensitive = true
}

output "keycloak_admin_password" {
  value     = data.terraform_remote_state.keycloak.outputs.keycloak_admin_password
  sensitive = true
}

output "keycloak_hostname_url" {
  value = data.terraform_remote_state.keycloak.outputs.keycloak_hostname_url
}

output "server_base_domain_realm_id" {
  value = keycloak_realm.server_base_domain.id
}
