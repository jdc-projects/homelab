variable "server_base_domain" {
  type        = string
  description = "Domain of the Truenas Scale instance."
}

variable "lldap_admin_password" {
  type        = string
  sensitive   = true
  description = "Password for the LLDAP admin user."
}
