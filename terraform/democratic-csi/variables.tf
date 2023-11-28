variable "truenas_api_key" {
  type        = string
  sensitive   = true
  description = "API key for the Truenas server."
}

variable "truenas_k8s_dataset" {
  type        = string
  description = "Parent dataset for PVs on the Truenas server."
}

variable "truenas_k8s_snapshot_dataset" {
  type        = string
  description = "Parent dataset for snapshot PVs on the Truenas server."
}

variable "truenas_ip_address" {
  type        = string
  sensitive   = true
  description = "Private IP address of the Truenas server."
}
