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

output "sentry_auth_token" {
  value       = data.kubernetes_secret.sentry_auth_token.data.token
  sensitive   = true
  description = "Org-scoped auth token for the jianyuan/sentry provider. App modules read this via remote_state and self-create their Sentry projects."
}
