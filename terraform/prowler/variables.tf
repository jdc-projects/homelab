variable "server_base_domain" {
  type        = string
  description = "Domain for applications."
}

variable "prowler_compliance_standards" {
  type        = list(string)
  description = "List of standards that Prowler should scan for compliance to. Must be supported by Prowler."
  default = [
    "cis_1.10_kubernetes",
    "cis_1.8_kubernetes",
  ]
}
