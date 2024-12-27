output "keycloak_admin_username" {
  value     = data.terraform_remote_state.keycloak.outputs.keycloak_admin_username
  sensitive = true
}

output "keycloak_admin_password" {
  value     = data.terraform_remote_state.keycloak.outputs.keycloak_admin_password
  sensitive = true
}

output "keycloak_domain" {
  value = data.terraform_remote_state.keycloak.outputs.keycloak_domain
}

output "keycloak_url" {
  value = data.terraform_remote_state.keycloak.outputs.keycloak_url
}

output "primary_realm_id" {
  value = keycloak_realm.primary.id
}

output "master_realm_id" {
  value = data.keycloak_realm.master.id
}

locals {
  keycloak_issuer_url = "${data.terraform_remote_state.keycloak.outputs.keycloak_url}/realms/${keycloak_realm.primary.realm}"
  keycloak_auth_url_base = "${local.keycloak_issuer_url}/protocol/openid-connect"
}

output "keycloak_issuer_url" {
  value = local.keycloak_issuer_url
}

output "keycloak_auth_url" {
  value = "${local.keycloak_auth_url_base}/auth"
}

output "keycloak_token_url" {
  value = "${local.keycloak_auth_url_base}/token"
}

output "keycloak_api_url" {
  value = "${local.keycloak_auth_url_base}/userinfo"
}

output "keycloak_logout_url" {
  value = "${local.keycloak_auth_url_base}/logout"
}
