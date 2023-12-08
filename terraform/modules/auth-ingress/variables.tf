variable "server_base_domain" {
  type        = string
  description = "Domain for applications."
}

variable "namespace" {
  type        = string
  description = "Namespace to put resources in."
}

variable "service_selector_app" {
  type        = string
  description = "Selector 'app' name for service."
}

variable "service_port" {
  type        = string
  description = "Target port for the service."
}

variable "url_subdomain" {
  type        = string
  description = "Subdomain for the URL ($url_subdomain.$server_base_domain)."
}
