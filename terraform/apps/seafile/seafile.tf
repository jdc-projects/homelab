resource "null_resource" "seafile_config_file_population" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
      find ./config -type f -exec sed -i'' -e "s#{{SERVER_BASE_DOMAIN}}#${var.server_base_domain}#g" {} \;
      find ./config -type f -exec sed -i'' -e "s#{{MARIADB_HOST}}#${helm_release.mariadb.name}#g" {} \;
      find ./config -type f -exec sed -i'' -e "s#{{MARIADB_ROOT_PASSWORD}}#${random_password.mariadb_root_password.result}#g" {} \;
      find ./config -type f -exec sed -i'' -e "s#{{FILESERVER_PORT}}#${kubernetes_service.seafile_fileserver.spec[0].port[0].target_port}#g" {} \;
      find ./config -type f -exec sed -i'' -e "s#{{NOTIFICATION_SERVER_PORT}}#${kubernetes_service.seafile_notification.spec[0].port[0].target_port}#g" {} \;
      find ./config -type f -exec sed -i'' -e "s#{{NOTIFICATION_JWT_PRIVATE_KEY}}#${random_password.seafile_notification_jwt_private_key.result}#g" {} \;
      find ./config -type f -exec sed -i'' -e "s#{{SMTP_HOST}}#${var.smtp_host}#g" {} \;
      find ./config -type f -exec sed -i'' -e "s#{{SMTP_USER}}#${var.smtp_username}#g" {} \;
      find ./config -type f -exec sed -i'' -e "s#{{SMTP_PASSWORD}}#${var.smtp_password}#g" {} \;
      find ./config -type f -exec sed -i'' -e "s#{{SMTP_PORT}}#${var.smtp_port}#g" {} \;
      find ./config -type f -exec sed -i'' -e "s#{{OAUTH_CLIENT_ID}}#${keycloak_openid_client.seafile.client_id}#g" {} \;
      find ./config -type f -exec sed -i'' -e "s#{{OAUTH_CLIENT_SECRET}}#${random_password.seafile_keycloak_client_secret.result}#g" {} \;
      find ./config -type f -exec sed -i'' -e "s#{{OAUTH_REALM_NAME}}#${data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id}#g" {} \;
    EOT
  }
}

data "local_sensitive_file" "seafile_ccnet_conf" {
  filename = "./config/ccnet.conf"

  depends_on = [null_resource.seafile_config_file_population]
}

data "local_sensitive_file" "seafile_seafile_conf" {
  filename = "./config/seafile.conf"

  depends_on = [null_resource.seafile_config_file_population]
}

data "local_sensitive_file" "seafile_seahub_settings_py" {
  filename = "./config/seahub_settings.py"

  depends_on = [null_resource.seafile_config_file_population]
}

resource "kubernetes_config_map" "seafile_config_files" {
  metadata {
    name      = "seafile-config-files"
    namespace = kubernetes_namespace.seafile.metadata[0].name
  }

  data = {
    "ccnet.conf"         = data.local_sensitive_file.seafile_ccnet_conf.content
    "seafile.conf"       = data.local_sensitive_file.seafile_seafile_conf.content
    "seahub_settings.py" = data.local_sensitive_file.seafile_seahub_settings_py.content
  }
}

resource "kubernetes_deployment" "seafile" {
  metadata {
    name      = "seafile"
    namespace = kubernetes_namespace.seafile.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "seafile"
      }
    }

    template {
      metadata {
        labels = {
          app = "seafile"
        }
      }

      spec {
        container {
          image = "seafileltd/seafile-mc:10.0.1"
          name  = "seafile"

          # volume_mount {
          #   mount_path = "/shared"
          #   name       = "seafile-data"
          # }

          volume_mount {
            mount_path = "/shared/seafile"
            name       = "seafile-config"
            read_only  = false
          }
        }

        # volume {
        #   name = "seafile-data"

        #   host_path {
        #     path = truenas_dataset.seafile.mount_point
        #   }
        # }

        volume {
          name = "seafile-config"

          config_map {
            name = kubernetes_config_map.seafile_config_files.metadata[0].name
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.seafile_config_files
    ]
  }
}
