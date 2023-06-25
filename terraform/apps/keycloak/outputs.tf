output "keycloak_admin_username" {
  value     = kubernetes_secret.keycloak_secret.data.KEYCLOAK_ADMIN_USER
  sensitive = true
}

output "keycloak_admin_password" {
  value     = kubernetes_secret.keycloak_secret.data.KEYCLOAK_ADMIN_PASSWORD
  sensitive = true
}

output "keycloak_hostname_url" {
  value = kubernetes_config_map.keycloak_configmap.data.KC_HOSTNAME_URL
}
