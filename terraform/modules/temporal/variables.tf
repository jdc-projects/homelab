variable "namespace" {
  type        = string
  description = "Namespace to deploy Temporal resources into."
}

variable "name_prefix" {
  type        = string
  default     = "temporal"
  description = "Name prefix for all resources."
}

variable "db_instances" {
  type        = number
  default     = 1
  description = "Number of CNPG instances for the Temporal database."
}

variable "is_db_hibernate" {
  type        = bool
  default     = false
  description = "Whether the Temporal DB should be in hibernate mode."
}

variable "es_host" {
  type        = string
  default     = null
  description = "OpenSearch host for advanced visibility. Null = SQL-only visibility."
}

variable "es_version" {
  type        = string
  default     = "v7"
  description = "Elasticsearch/OpenSearch version for Temporal index templates."
}

variable "db_image" {
  type        = string
  default     = "ghcr.io/cloudnative-pg/postgresql:16.14-standard-trixie"
  description = "CloudNative-PG Postgres image. Tags: https://github.com/cloudnative-pg/postgresql-containers/pkgs/container/postgresql"
}

variable "server_image" {
  type        = string
  default     = "temporalio/auto-setup:1.26.2"
  description = "Temporal server (auto-setup) image. Releases: https://github.com/temporalio/temporal/releases"
}

variable "ui_image" {
  type        = string
  default     = "temporalio/ui:2.47.2"
  description = "Temporal UI image. Releases: https://github.com/temporalio/ui/releases"
}

variable "cors_origins" {
  type        = string
  default     = null
  description = "CORS origins for Temporal UI, e.g. https://posthog.example.com."
}

variable "ui_domain" {
  type        = string
  default     = null
  description = "Domain for Temporal UI ingress. Null = UI not exposed externally."
}
