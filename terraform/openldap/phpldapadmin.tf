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
            - bind_id: "cn=${random_password.openldap_admin_username.result},dc=idm,dc=homelab"
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
            value = "info"
          }

          volume_mount {
            name       = "custom-env"
            sub_path   = "env.yaml"
            mount_path = "/container/environment/01-custom/env.yaml"
          }

          resources {
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }

            limits = {
              cpu      = "500m"
              memberOf = "512Mi"
            }
          }
        }

        volume {
          name = "custom-env"

          config_map {
            name = kubernetes_config_map.phpldapadmin_env[0].metadata[0].name
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.phpldapadmin_env
    ]
  }
}
