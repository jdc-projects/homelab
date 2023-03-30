variable "server_base_domain" {
  type        = string
  description = "Domain of the Truenas Scale instance."
}

variable "truenas_api_key" {
  type        = string
  sensitive   = true
  description = "API key for the Truenas server instance."
}

variable "nextcloud_admin_username" {
  type        = string
  sensitive   = true
  description = "Username for the Nextcloud admin user."
}

variable "nextcloud_admin_password" {
  type        = string
  sensitive   = true
  description = "Password for the Nextcloud admin user."
}
