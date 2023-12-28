resource "ssh_resource" "fs_inotify_update" {
  host        = var.k3s_ip_address
  user        = var.k3s_username
  private_key = var.k3s_ssh_private_key

  commands = [
    "sudo swapoff -a",
  ]
}
