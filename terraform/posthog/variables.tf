variable "server_base_domain" {
  type        = string
  description = "Domain for applications."
}

variable "is_db_hibernate" {
  type        = bool
  default     = false
  description = "Whether DBs should be in hibernate mode."
}

variable "is_first_deploy" {
  type        = bool
  default     = false
  description = "Set true for an initial deployment on a fresh database. Skips async migration setup during Django app startup, before migrate creates posthog_asyncmigration. Set false after the first successful migration."
}
