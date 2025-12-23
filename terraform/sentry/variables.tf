variable "server_base_domain" {
  description = "Base domain for the server"
  type        = string
}

variable "is_db_hibernate" {
  description = "Whether to hibernate the database"
  type        = bool
  default     = false
}
