resource "harbor_registry" "docker_hub" {
  provider_name = "docker-hub"
  name          = "docker-hub"
  endpoint_url  = "https://hub.docker.com"
}

resource "harbor_project" "docker_hub" {
  name        = "docker-hub"
  registry_id = harbor_registry.docker_hub.registry_id
}

resource "harbor_retention_policy" "docker_hub" {
    scope = harbor_project.docker_hub.id
    schedule = "Daily"

    rule {
        n_days_since_last_pull = 30
    }
}

resource "harbor_robot_account" "docker_hub_reader" {
  name        = "docker-hub-reader"
  description = "Docker Hub proxy reader"
  level       = "project"

  permissions {
    access {
      action   = "pull"
      resource = "repository"
    }
    kind      = "project"
    namespace = harbor_project.docker_hub.name
  }

  secret = random_password.docker_hub_reader_secret.result
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
          username: ${harbor_robot_account.docker_hub_reader.full_name}
          password: ${harbor_robot_account.docker_hub_reader.secret}
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
