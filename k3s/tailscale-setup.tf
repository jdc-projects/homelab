resource "ssh_resource" "tailscale_setup" {
  host        = var.k3s_ip_address
  user        = var.k3s_username
  private_key = var.k3s_ssh_private_key

  timeout = "1m"

  file {
    content     = <<-EOF
      net.ipv4.ip_forward = 1
      net.ipv6.conf.all.forwarding = 1
    EOF
    destination = "~/99-tailscale.conf"
  }

  commands = [
    "sudo mv 99-tailscale.conf /etc/sysctl.d/99-tailscale.conf",
    "sudo sysctl -p /etc/sysctl.d/99-tailscale.conf",
    "sudo tailscale up --advertise-exit-node --advertise-routes ${var.k3s_subnet} --authkey ${var.tailscale_auth_key}",
  ]

  depends_on = [
    ssh_resource.apt_packages
  ]
}
