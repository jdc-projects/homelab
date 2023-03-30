variable "server_base_domain" {
  type        = string
  description = "Domain of the Truenas Scale instance."
}

variable "jdc_projects_runners_app_id" {
  type        = string
  description = ""
}

variable "jdc_projects_runners_app_installation_id" {
  type        = string
  description = ""
}

variable "jdc_projects_runners_app_private_key" {
  type        = string
  sensitive   = true
  description = ""
}

variable "cloudflare_acme_token" {
  type        = string
  sensitive   = true
  description = ""
}
