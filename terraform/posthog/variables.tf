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

variable "openai_api_key" {
  type        = string
  sensitive   = true
  default     = null
  description = "OpenAI API key for PostHog AI features (SQL gen, regex gen, session summaries)."
}

variable "anthropic_api_key" {
  type        = string
  sensitive   = true
  default     = null
  description = "Anthropic API key for the Max AI assistant."
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
