variable "server_base_domain" {
  type        = string
  description = "Domain for applications."
}

variable "smtp_host" {
  type        = string
  description = "Hostname of the SMTP server."
}

variable "smtp_port" {
  type        = string
  description = "Port of the SMTP server."
}

variable "smtp_username" {
  type        = string
  description = "Username for the SMTP server."
}

variable "smtp_password" {
  type        = string
  sensitive   = true
  description = "Password for the SMTP server."
}
