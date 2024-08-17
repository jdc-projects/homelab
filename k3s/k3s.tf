locals {
  rancher_directory       = "/etc/rancher"
  k3s_directory           = "${local.rancher_directory}/k3s"
  kubelet_config_location = "${local.k3s_directory}/kubelet.config"
}

resource "ssh_resource" "k3s_kubelet_config" {
  host        = var.k3s_ip_address
  user        = var.k3s_username
  private_key = var.k3s_ssh_private_key

  file {
    content     = <<-EOF
      apiVersion: kubelet.config.k8s.io/v1beta1
      kind: KubeletConfiguration
      maxPods: 200
    EOF
    destination = local.kubelet_config_location
  }

  pre_commands = [
    "sudo mkdir -p ${local.k3s_directory}",
    "sudo chown -R k3s ${local.rancher_directory}",
  ]

  timeout = "30s"
}

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
      kubelet-arg: "config=${local.kubelet_config_location}"
    EOF
    destination = "${local.k3s_directory}/config.yaml"
  }

  commands = [
    "curl -sfL https://get.k3s.io | sh -",
  ]

  timeout = "1m"

  depends_on = [
    ssh_resource.k3s_kubelet_config,
  ]
}
