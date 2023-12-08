variable "server_base_domain" {
  type        = string
  description = "Domain for applications."
}

variable "namespace" {
  type        = string
  description = "Namespace to put resources in."
}

variable "external_name" {
  type        = string
  description = "External domain or IP for to expose."
}

variable "external_scheme" {
  type        = string
  description = "Scheme (http or https) for the external domain or IP."
}

variable "external_port" {
  type        = string
  description = "Port for the external domain or IP."
}

variable "path_prefix" {
  type        = string
  description = "Path prefix for the ingress."
}
