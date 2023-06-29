output "keycloak_admin_username" {
  value     = kubernetes_secret.keycloak_secret.data.KEYCLOAK_ADMIN_USER
  sensitive = true
}

output "keycloak_admin_password" {
  value     = kubernetes_secret.keycloak_secret.data.KEYCLOAK_ADMIN_PASSWORD
  sensitive = true
}

output "keycloak_hostname_url" {
  value = null_resource.keycloak_domain.triggers.keycloak_domain
}
