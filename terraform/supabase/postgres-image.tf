locals {
  postgres_version = "15.1.0.147"
}

resource "docker_registry_image" "postgres" {
  name = docker_image.postgres.name
  keep_remotely = true

  depends_on = [
    harbor_project.supabase
  ]
}

resource "docker_image" "postgres" {
  name = "${HARBOR_URL}/${harbor_project.supabase.name}postgres:${local.postgres_version}" # *****

  build {
    context = "${module.path}/docker/"

    build_arg = {
      VERSION = local.postgres_version
    }

    auth_config = {
      host_name = ""
      # ***** https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/image#nestedblock--build--auth_config
    }
  }

  triggers = {
    dockerfile = filesha256("${module.path}/docker/Dockerfile")
  }
}
