resource "kubernetes_config_map" "phpldapadmin_env" {
  count = var.enable_phpldapadmin ? 1 : 0

  metadata {
    name      = "phpldapadmin-env"
    namespace = kubernetes_namespace.openldap.metadata[0].name
  }

  data = {
    "env.yaml" = <<-EOF
      PHPLDAPADMIN_LDAP_HOSTS:
        - OpenLDAP:
          - server:
            - host: "openldap"
            - port: ${kubernetes_config_map.openldap_env.data.LDAP_PORT_NUMBER}
          - login:
            - bind_id: "cn=${random_password.openldap_admin_username.result},dc=idm,dc=${var.server_base_domain}"
    EOF
  }
}

resource "kubernetes_deployment" "phpldapadmin" {
  count = var.enable_phpldapadmin ? 1 : 0

  metadata {
    name      = "phpldapadmin"
    namespace = kubernetes_namespace.openldap.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "phpldapadmin"
      }
    }

    template {
      metadata {
        labels = {
          app = "phpldapadmin"
        }
      }

      spec {
        container {
          image = "osixia/phpldapadmin:0.9.0"
          name  = "phpldapadmin"

          env {
            name  = "LOG_LEVEL"
            value = "debug"
          }

          volume_mount {
            name       = "custom-env"
            sub_path   = "env.yaml"
            mount_path = "/container/environment/01-custom/env.yaml"
          }

          #   volume_mount {
          #     mount_path = "/data"
          #     name       = "phpldapadmin-data"
          #   }
        }

        volume {
          name = "custom-env"

          config_map {
            name = kubernetes_config_map.phpldapadmin_env[0].metadata[0].name
          }
        }

        # volume {
        #   name = "vaultwarden-data"

        #   host_path {
        #     path = truenas_dataset.vaultwarden_dataset.mount_point
        #   }
        # }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.phpldapadmin_env
    ]
  }
}