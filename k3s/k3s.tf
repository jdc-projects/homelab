resource "ssh_resource" "k3s_provisioning" {
  host        = var.k3s_ip_address
  user        = var.k3s_username
  private_key = var.k3s_ssh_private_key

  file {
    content     = <<-EOF
      tls-san:
        - "${var.server_base_domain}"
      disable:
        - "traefik"
        - "local-storage"
      cluster-init: true
    EOF
    destination = "/etc/rancher/k3s/config.yaml"
  }

  commands = [
    "curl -sfL https://get.k3s.io | sh -",
  ]
}
