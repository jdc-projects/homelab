output "api_key" {
  value       = one(random_password.api_key[*].result)
  sensitive   = true
  description = "API key for if that method of authentication is enabled."
}
