resource "ssh_resource" "disk_expansion" {
  host        = var.k3s_ip_address
  user        = var.k3s_username
  private_key = var.k3s_ssh_private_key

  commands = [
    "sudo lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv",
    "sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv",
  ]
}
