variable "server_base_domain" {
  type        = string
  description = "Domain for applications."
}

variable "github_org_name" {
  type        = string
  description = ""
}

variable "github_org_runners_app_id" {
  type        = string
  description = ""
}

variable "github_org_runners_app_installation_id" {
  type        = string
  description = ""
}

variable "github_org_runners_app_private_key" {
  type        = string
  sensitive   = true
  description = ""
}
