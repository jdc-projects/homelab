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
  description = "Port on the application / endpoint that the service should connect to. If using an existing service, this should be the port on the service."
}

variable "selector" {
  type        = map(string)
  description = "Selector that the service should use. Not used if external."
  default     = null

  validation {
    condition     = !((null == var.selector && "" == var.external_name) || (null != var.selector && "" != var.external_name)) # *****
    error_message = "Exactly one of 'selector', 'external_name', 'existing_service' must be set."
  }
}

variable "external_name" {
  type        = string
  description = "External domain or IP for to expose. Not used if internal."
  default     = ""
}

variable "existing_service_name" {
  type        = string
  description = "Name of existing service to be used. Must be pointing to an internal endpoint."
  default     = ""
}

variable "existing_service_namespace" {
  type        = string
  description = "Namespace of existing service to be used. Must be pointing to an internal endpoint."
  default     = ""

  validation {
    condition = ("" == var.existing_service_namespace && "" == var.existing_service_name) || ("" != var.existing_service_namespace && "" != var.existing_service_name)
    error_message = "If 'existing_service_name' is set, 'existing_service_namespace' must also be set."
  }
}

variable "priority" {
  type        = number
  description = "Priority for the ingress. Larger number = higher priority. 0 uses built-in priority management."
  default     = 0
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
