output "admin_username" {
  value     = random_password.admin_username.result
  sensitive = true
}

output "admin_password" {
  value     = random_password.admin_password.result
  sensitive = true
}
