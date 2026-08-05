variable "server_base_domain" {
  type        = string
  description = "Domain for applications."
}

variable "is_db_hibernate" {
  type        = bool
  description = "Whether the DB should be in hibernate mode."
  default     = false
}
