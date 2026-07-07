output "api_key" {
  value       = one(random_password.api_key[*].result)
  sensitive   = true
  description = "API key for if that method of authentication is enabled."
}

output "keycloak_auth_middleware_name" {
  value       = var.do_enable_keycloak_auth ? "${var.name}-keycloak-auth" : null
  description = "Name of the Keycloak auth middleware when do_enable_keycloak_auth is true. Other ingresses on the same host can reference this to share a single session cookie / client."
}

output "keycloak_auth_middleware_namespace" {
  value       = var.do_enable_keycloak_auth ? var.namespace : null
  description = "Namespace of the Keycloak auth middleware when do_enable_keycloak_auth is true."
}
