variable "server_base_domain" {
  type        = string
  description = "Domain of the Truenas Scale instance."
}

variable "cloudflare_ddns_token" {
  type        = string
  description = "API key for the dynamic DNS for Cloudflare."
}
