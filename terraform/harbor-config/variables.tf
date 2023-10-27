variable "server_base_domain" {
  type        = string
  description = "Domain of the Truenas Scale instance."
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

variable "truenas_username" {
  type        = string
  sensitive   = true
  description = "Username for the Truenas server."
}

variable "truenas_ssh_private_key" {
  type        = string
  sensitive   = true
  description = "SSH private key for the Truenas server."
}

variable "truenas_ip_address" {
  type        = string
  sensitive   = true
  description = "IP address for the Truenas server."
}
