output "api_key" {
  value       = random_password.api_key.result
  sensitive   = true
  description = "API key for if that method of authentication is enabled."
}
