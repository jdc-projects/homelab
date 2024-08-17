variable "server_base_domain" {
  type        = string
  description = "Domain for applications."
}

variable "k3s_username" {
  type        = string
  sensitive   = true
  description = "Username for the k3s server."
}

variable "k3s_ssh_private_key" {
  type        = string
  sensitive   = true
  description = "SSH private key for the k3s server."
}

variable "k3s_ip_address" {
  type        = string
  sensitive   = true
  description = "IP address for the k3s server."
}

variable "k3s_subnet" {
  type        = string
  sensitive   = true
  description = "Subnet that the k3s server is in. (e.g. 192.168.1.0/24)"
}

variable "tailscale_auth_key" {
  type        = string
  sensitive   = true
  description = "Auth key for the tailscale client."
}
