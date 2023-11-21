variable "nfs_ip_address" {
  type = string
  sensitive = true
  description = "IP address of the NFS server."
}

variable "nfs_share" {
  type = string
  sensitive = true
  description = "Share on the NFS server."
}
