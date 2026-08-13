output "admin_key" {
  value     = random_password.cap_admin_key.result
  sensitive = true
}
