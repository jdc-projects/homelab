variable "server_base_domain" {
  type        = string
  description = "Domain for applications."
}

variable "company_name" {
  type        = string
  default     = "JDC Projects"
  description = "ERPNext company name."
}

variable "company_abbr" {
  type        = string
  default     = "JDCP"
  description = "ERPNext company abbreviation (2-5 chars)."
}

variable "country" {
  type        = string
  default     = "United Kingdom"
  description = "Country for ERPNext company and regional settings."
}

variable "currency" {
  type        = string
  default     = "GBP"
  description = "Default currency for ERPNext company."
}
