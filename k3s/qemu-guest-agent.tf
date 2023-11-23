resource "ssh_resource" "qemu_guest_agent_install" {
  host        = var.k3s_ip_address
  user        = var.k3s_username
  private_key = var.k3s_ssh_private_key

  commands = [
    "sudo apt update",
    "sudo apt install -y qemu-guest-agent",
  ]
}
