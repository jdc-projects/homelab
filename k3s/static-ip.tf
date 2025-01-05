

resource "ssh_resource" "static_ip_setup" {
  host        = var.k3s_ip_address
  user        = var.k3s_username
  private_key = var.k3s_ssh_private_key

  file {
    content     = <<-EOF
      network:
        ethernets:
          eno1:
            dhcp4: false
            addresses:
              - ${var.k3s_ip_address}/${var.k3s_subnet_cidr}
            routes:
              - to: default
                via: ${var.gateway_ip}
            nameservers:
              addresses:
                - ${var.gateway_ip}
        version: 2
      EOF
    destination = "~/20-static-ip.yaml"
  }

  commands = [
    "sudo mv ~/20-static-ip.yaml /etc/netplan/20-static-ip.yaml",
  ]
}
