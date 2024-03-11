output "affine_admin_email" {
  value     = "${random_password.affine_admin_username.result}@${var.server_base_domain}"
  sensitive = true
}

output "affine_admin_password" {
  value     = random_password.affine_admin_password.result
  sensitive = true
}
