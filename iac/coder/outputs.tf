output "coder_api_token" {
  description = "Owner API token auto-minted by the bootstrap job (bootstrap.tf), consumed by iac/coder-template for the coder/coderd provider."
  value       = data.kubernetes_secret.coder_api_token.data["token"]
  sensitive   = true
}
