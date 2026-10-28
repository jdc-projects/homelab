variable "server_base_domain" {
  type        = string
  description = "Domain for applications."
}

variable "openbao_root_token" {
  type        = string
  description = "OpenBao root token (OPENBAO_ROOT_TOKEN GitHub secret), minted by the iac/openbao bootstrap job."
  sensitive   = true
}
