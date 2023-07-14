variable "server_base_domain" {
  type        = string
  description = "Domain of the Truenas Scale instance."
}

variable "truenas_api_key" {
  type        = string
  sensitive   = true
  description = "API key for the Truenas server instance."
}
