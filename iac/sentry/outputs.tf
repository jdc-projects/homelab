output "sentry_domain" {
  value       = local.sentry_domain
  description = "The Sentry web URL host."
}

output "admin_email" {
  value       = var.admin_email
  description = "Email of the initial Sentry admin user."
}

output "admin_password" {
  value       = random_password.sentry_admin_password.result
  sensitive   = true
  description = "Initial Sentry admin password. Retrieve with: tofu output -raw admin_password"
}
