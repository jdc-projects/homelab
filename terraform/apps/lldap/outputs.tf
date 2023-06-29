output "lldap_admin_password" {
  value     = random_password.lldap_admin_password.result
  sensitive = true
}
