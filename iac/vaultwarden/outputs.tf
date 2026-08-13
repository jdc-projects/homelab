output "admin_token" {
  value     = random_password.vaultwarden_admin_token.result
  sensitive = true
}
