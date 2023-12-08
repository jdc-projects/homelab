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
  type        = number
  description = "Port for the external domain or IP."
}

variable "url_subdomain" {
  type        = string
  description = "Subdomain for the URL ($url_subdomain.$server_base_domain)."
}
