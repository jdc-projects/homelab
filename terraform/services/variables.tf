variable "server_base_domain" {
  type        = string
  description = "Domain for applications."
}

variable "cloudflare_ddns_token" {
  type        = string
  sensitive   = true
  description = "API key for the dynamic DNS for Cloudflare."
}

variable "idrac_username" {
  type        = string
  sensitive   = true
  description = "Username for server idrac."
}

variable "idrac_password" {
  type        = string
  sensitive   = true
  description = "Password for server idrac."
}

variable "k3s_ip_address" {
  type        = string
  sensitive   = true
  description = "IP address of the K3s server."
}
