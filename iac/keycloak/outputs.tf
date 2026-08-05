output "keycloak_admin_username" {
  value     = random_password.keycloak_admin_username.result
  sensitive = true
}

output "keycloak_admin_password" {
  value     = random_password.keycloak_admin_password.result
  sensitive = true
}

output "keycloak_domain" {
  value = local.keycloak_domain
}

output "keycloak_url" {
  value = "https://${local.keycloak_domain}"
}
