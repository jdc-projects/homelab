variable "server_base_domain" {
  type        = string
  description = "Domain of the Truenas Scale instance."
}

variable "cloudflare_acme_token" {
  type        = string
  sensitive   = true
  description = ""
}
