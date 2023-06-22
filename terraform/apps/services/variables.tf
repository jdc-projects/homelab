variable "server_base_domain" {
  type        = string
  description = "Domain of the Truenas Scale instance."
}

variable "truenas_api_key" {
  type        = string
  sensitive   = true
  description = "API key for the Truenas server instance."
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
