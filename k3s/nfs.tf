resource "ssh_resource" "nfs_provisioning" {
  host        = var.k3s_ip_address
  user        = var.k3s_username
  private_key = var.k3s_ssh_private_key

  commands = [
    "sudo apt update",
    "sudo apt install nfs-common",
  ]
}
