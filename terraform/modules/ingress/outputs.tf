output "api_key" {
  value       = one(random_password.api_key[*].result)
  sensitive   = true
  description = "The generated API key when auth_mode is \"api-key\". null otherwise."
}

output "auth_interactive_middleware_name" {
  value       = var.auth_mode == "oidc-interactive" ? "${var.name}-auth-interactive" : null
  description = "Name of the interactive (full OIDC flow) auth middleware when auth_mode is \"oidc-interactive\". Other ingresses on the same host can reference this to share a single session cookie / client."
}

output "auth_interactive_middleware_namespace" {
  value       = var.auth_mode == "oidc-interactive" ? var.namespace : null
  description = "Namespace of the interactive auth middleware when auth_mode is \"oidc-interactive\"."
}

output "auth_api_middleware_name" {
  value       = var.auth_mode == "oidc-api" ? "${var.name}-auth-api" : null
  description = "Name of the api (OIDC offload) auth middleware when auth_mode is \"oidc-api\". Other ingresses can reference this to share token validation / header injection."
}

output "auth_api_middleware_namespace" {
  value       = var.auth_mode == "oidc-api" ? var.namespace : null
  description = "Namespace of the api auth middleware when auth_mode is \"oidc-api\"."
}
