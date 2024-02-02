locals {
  ubuntu_version_name = "jammy"
}

resource "ssh_resource" "apt_packages" {
  host        = var.k3s_ip_address
  user        = var.k3s_username
  private_key = var.k3s_ssh_private_key

  commands = [
    "curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/${local.ubuntu_version_name}.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null",
    "curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/${local.ubuntu_version_name}.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list",
    "sudo apt update",
    "sudo apt install -y cron zfsutils-linux git cockpit cockpit-pcp tailscale at htop net-tools vim",
  ]
}
