variable "server_base_domain" {
  type        = string
  description = "Domain for applications."
}

variable "enable_postgres_operator_ui" {
  type        = bool
  description = "Whether to enable the postgres operator portal (true = enabled)."
  default     = false
}
