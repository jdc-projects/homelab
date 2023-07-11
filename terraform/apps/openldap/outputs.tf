output "admin_username" {
  value     = random_password.openldap_admin_username.result
  sensitive = true
}

output "admin_password" {
  value     = random_password.openldap_admin_password.result
  sensitive = true
}

output "test_admin_username" {
  value     = random_password.openldap_test_admin_username.result
  sensitive = true
}

output "test_admin_password" {
  value     = random_password.openldap_test_admin_password.result
  sensitive = true
}

output "test_user_username" {
  value     = random_password.openldap_test_user_username.result
  sensitive = true
}

output "test_user_password" {
  value     = random_password.openldap_test_user_password.result
  sensitive = true
}

output "test_guest_username" {
  value     = random_password.openldap_test_guest_username.result
  sensitive = true
}

output "test_guest_password" {
  value     = random_password.openldap_test_guest_password.result
  sensitive = true
}

output "test_disabled_username" {
  value     = random_password.openldap_test_disabled_username.result
  sensitive = true
}

output "test_disabled_password" {
  value     = random_password.openldap_test_disabled_password.result
  sensitive = true
}
