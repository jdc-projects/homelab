resource "harbor_registry" "docker_hub" {
  provider_name = "docker-hub"
  name          = "docker-hub"
  endpoint_url  = "https://hub.docker.com"
}

resource "harbor_project" "docker_hub" {
  name        = "docker-hub"
  registry_id = harbor_registry.docker_hub.registry_id
}

resource "harbor_user" "docker_hub_reader" {
  username  = "docker-hub-reader"
  password  = random_password.docker_hub_reader_password.result
  full_name = "Docker Hub Reader"
  email     = "docker-hub-reader@${var.server_base_domain}"
}

resource "harbor_project_member_user" "docker_hub_reader" {
  project_id = harbor_project.docker_hub.id
  user_name  = harbor_user.docker_hub_reader.username
  role       = "limitedguest"
}

resource "local_file" "k3s_registries_config" {
  content  = <<-EOF
    mirrors:
      docker.io:
        endpoint:
          - "https://harbor.${var.server_base_domain}/${harbor_project.docker_hub.name}"
    configs:
      "harbor.${var.server_base_domain}/${harbor_project.docker_hub.name}":
        auth:
          username: ${harbor_user.docker_hub_reader.username}
          password: ${harbor_user.docker_hub_reader.password}
  EOF
  filename = "./registries.yaml"
}

resource "ssh_sensitive_resource" "k3s_registries_config_copy" {
  host        = var.truenas_ip_address
  user        = var.truenas_username
  private_key = var.truenas_ssh_private_key

  file {
    source      = local_file.k3s_registries_config.filename
    destination = "/etc/rancher/k3s/registries.yaml"
  }

  commands = [
    "systemctl reload-or-restart k3s"
  ]

  lifecycle {
    replace_triggered_by = [
      local_file.k3s_registries_config
    ]
  }
}
