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
  description = "Path for the URL ($domain/$path)"
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

variable "do_enable_cloudflare_real_ip_middleware" {
  type        = bool
  description = "True to enable Cloudflare Real IP middleware."
  default     = true
}

variable "do_enable_geoblock" {
  type        = bool
  description = "True to enable Geoblock middleware."
  default     = true
}

variable "do_enable_crowdsec_bouncer" {
  type        = bool
  description = "True to enable Crowdsec Bouncer middleware."
  default     = true
}

variable "do_enable_api_key_auth" {
  type        = bool
  description = "True to enable API key authentication middleware."
  default     = false
}

variable "extra_middlewares" {
  type        = list(map(string))
  description = "Extra middlewares to use."
  default     = []
}
