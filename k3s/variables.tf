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

variable "k3s_subnet_cidr" {
  type        = string
  sensitive   = true
  description = "CIDR for the subnet that the k3s server is in. (e.g. 24 for 192.168.100.0/24)"
}

variable "gateway_ip" {
  type        = string
  sensitive   = true
  description = "Gateway IP for the LAN (e.g. 192.168.100.1)"
}

variable "tailscale_auth_key" {
  type        = string
  sensitive   = true
  description = "Auth key for the tailscale client."
}

variable "ghcr_package_read_token" {
  type        = string
  sensitive   = true
  description = "PAT for reading Github packages."
}
