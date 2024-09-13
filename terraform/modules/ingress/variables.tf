variable "name" {
  type        = string
  description = "Name / prefix used for resource names."
}

variable "namespace" {
  type        = string
  description = "Namespace to put resources in. Should match the namespace of the endpoint / application."
}

variable "domain" {
  type        = string
  description = "Domain for the URL."
}

variable "path" {
  type        = string
  description = "Path for the URL ($domain/$path/)"
  default     = ""
}

variable "target_port" {
  type        = number
  description = "Port on the application / endpoint that the service should connect to."
}

variable "selector" {
  type        = map(string)
  description = "Selector that the service should use."
}
