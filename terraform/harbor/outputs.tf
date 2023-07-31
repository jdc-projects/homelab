output "harbor_admin_username" {
  value = "admin"
}

output "harbor_admin_password" {
  value     = random_password.harbor_admin_password
  sensitive = true
}
