output "keycloak_admin_username" {
  value     = random_password.keycloak_admin_username
  sensitive = true
}

output "keycloak_admin_password" {
  value     = random_password.keycloak_admin_password
  sensitive = true
}

output "keycloak_hostname_url" {
  value = kubernetes_config_map.keycloak_configmap.data.KC_HOSTNAME_URL
}
