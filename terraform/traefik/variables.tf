variable "server_base_domain" {
  type        = string
  description = "Domain for applications."
}

variable "cloudflare_acme_token" {
  type        = string
  sensitive   = true
  description = ""
}
