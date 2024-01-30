resource "ssh_resource" "k3s_provisioning" {
  host        = var.k3s_ip_address
  user        = var.k3s_username
  private_key = var.k3s_ssh_private_key

  file {
    content     = <<-EOF
      tls-san:
        - "kubernetes.${var.server_base_domain}"
      disable:
        - "traefik"
        - "local-storage"
      cluster-cidr: "10.42.0.0/16"
      service-cidr: "10.43.0.0/16"
      cluster-dns: "10.43.0.10"
      cluster-domain: "cluster.local"
      advertise-address: "${var.k3s_ip_address}"
      cluster-init: true
    EOF
    destination = "/etc/rancher/k3s/config.yaml"
  }

  pre_commands = [
    "sudo mkdir -p /etc/rancher/k3s",
    "sudo chown -R k3s /etc/rancher",
  ]

  commands = [
    "curl -sfL https://get.k3s.io | sh -",
  ]
}
