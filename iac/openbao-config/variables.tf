variable "server_base_domain" {
  type        = string
  description = "Domain for applications."
}

variable "openbao_k8s_jwt" {
  type        = string
  description = "Short-lived ServiceAccount JWT (kubectl create token openbao-config -n openbao --audience openbao), exchanged for a Vault token via Kubernetes auth by the provider."
  sensitive   = true
}
