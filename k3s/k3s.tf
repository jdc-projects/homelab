locals {
  rancher_directory       = "/etc/rancher"
  k3s_directory           = "${local.rancher_directory}/k3s"
  kubelet_config_location = "${local.k3s_directory}/kubelet.config"
}

resource "ssh_resource" "k3s_provisioning" {
  host        = var.k3s_ip_address
  user        = var.k3s_username
  private_key = var.k3s_ssh_private_key

  file {
    content     = <<-EOF
      apiVersion: kubelet.config.k8s.io/v1beta1
      kind: KubeletConfiguration
      maxPods: 500
    EOF
    destination = local.kubelet_config_location
  }

  file {
    content     = <<-EOF
      tls-san:
        - "kubernetes.${var.server_base_domain}"
      disable:
        - "traefik"
        - "local-storage"
      cluster-cidr: "10.42.0.0/16"
      service-cidr: "10.43.0.0/16"
      service-node-port-range: "27000-32767"
      cluster-dns: "10.43.0.10"
      cluster-domain: "cluster.local"
      advertise-address: "${var.k3s_ip_address}"
      cluster-init: true
      kubelet-arg: "config=${local.kubelet_config_location}"
      # Expose embedded etcd metrics as plaintext HTTP so Prometheus can scrape
      # them without TLS certs. `etcd-expose-metrics` enables the listener but
      # binds to 127.0.0.1 only; the etcd-arg below adds the node's LAN IP so
      # pods in the cluster network can reach it. Localhost is kept for
      # node-side debugging. Required for iac/prometheus/ ScrapeConfig
      # discovery. Ref: https://docs.k3s.io/cli/server
      etcd-expose-metrics: true
      etcd-arg:
        - "listen-metrics-urls=http://127.0.0.1:2381,http://${var.k3s_ip_address}:2381"
    EOF
    destination = "${local.k3s_directory}/config.yaml"
  }

  file {
    content     = <<-EOF
      mirrors:
        ghcr.io:
          endpoint:
            - https://ghcr.io
      configs:
        ghcr.io:
          auth:
            token: ${var.ghcr_package_read_token}
    EOF
    destination = "${local.k3s_directory}/registries.yaml"
  }

  pre_commands = [
    "sudo mkdir -p ${local.k3s_directory}",
    "sudo chown -R k3s ${local.rancher_directory}",
  ]

  commands = [
    "curl -sfL https://get.k3s.io | sh -",
  ]

  timeout = "1m"
}
