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
  description = "Selector that the service should use. Not used if external."
  default     = null

  validation {
    condition     = !((null == var.selector && "" == var.external_name) || (null != var.selector && "" != var.external_name))
    error_message = "Either 'selector' or 'external_name' must be set."
  }
}

variable "external_name" {
  type        = string
  description = "External domain or IP for to expose. Not used if internal."
  default     = ""
}

variable "is_external_scheme_http" {
  type        = string
  description = "True if scheme for external endpoint is http. False if HTTPS. Not used if internal."
  default     = true
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

variable "do_enable_keycloak_auth" {
  type        = bool
  description = "True to enable Keycloak authentication middleware."
  default     = false
}

variable "is_keycloak_auth_admin_mode" {
  type        = bool
  description = "True for admin-only (system_admins) auth. False for all users."
  default     = false
}

variable "extra_middlewares" {
  type        = list(map(string))
  description = "Extra middlewares to use."
  default     = []
}
