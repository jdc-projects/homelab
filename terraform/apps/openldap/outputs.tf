output "openldap_username" {
  value     = random_password.openldap_admin_username.result
  sensitive = true
}

output "openldap_password" {
  value     = random_password.openldap_admin_password.result
  sensitive = true
}
