output "keycloak_admin_username" {
  value     = random_password.keycloak_admin_username.result
  sensitive = true
}

output "keycloak_admin_password" {
  value     = random_password.keycloak_admin_password.result
  sensitive = true
}

output "keycloak_url" {
  value = "https://${local.keycloak_domain}"
}

output "primary_realm_id" {
  value = keycloak_realm.primary.id
}

output "master_realm_id" {
  value = data.keycloak_realm.master.id
}

output "keycloak_issuer_url" {
  value = "https://${local.keycloak_domain}/realms/${keycloak_realm.primary.realm}"
}

locals {
  keycloak_auth_url_base = "https://${local.keycloak_domain}/realms/${keycloak_realm.primary.realm}/protocol/openid-connect"
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
