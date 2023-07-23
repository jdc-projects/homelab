variable "server_base_domain" {
  type        = string
  description = "Domain of the Truenas Scale instance."
}

variable "namespace" {
  type        = string
  description = "Namespace to put resources in."
}

variable "path_prefix" {
  type        = string
  description = "Path prefix for the ingress."
}

variable "service_selector_app" {
  type        = string
  description = "Selector 'app' name for service."
}

variable "service_port" {
  type        = string
  description = "Target port for the service."
}
