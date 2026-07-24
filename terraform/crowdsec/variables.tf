variable "crowdsec_enroll_key" {
  type        = string
  sensitive   = true
  description = "Enroll key for the Crowdsec console"
}

variable "server_base_domain" {
  type        = string
  description = "Base domain for service hostnames; used by appsec hooks to scope per-host exemptions."
}
