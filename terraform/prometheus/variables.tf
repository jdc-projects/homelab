variable "server_base_domain" {
  type        = string
  description = "Domain for applications."
}

variable "smtp_host" {
  type        = string
  description = "SMTP server host for Alertmanager email notifications."
}

variable "smtp_port" {
  type        = number
  description = "SMTP server port for Alertmanager email notifications."
}

variable "smtp_username" {
  type        = string
  description = "SMTP username for Alertmanager email notifications."
}

variable "smtp_password" {
  type        = string
  sensitive   = true
  description = "SMTP password for Alertmanager email notifications."
}

variable "admin_email" {
  type        = string
  description = "Email address for cluster admin notifications (Alertmanager, etc.)."
}
