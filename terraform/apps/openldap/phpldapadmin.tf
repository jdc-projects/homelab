resource "kubernetes_config_map" "phpldapadmin_env" {
  metadata {
    name      = "phpldapadmin-env"
    namespace = kubernetes_namespace.openldap.metadata[0].name
  }

  data = {
    PHPLDAPADMIN_LDAP_HOSTS = "idm2.${var.server_base_domain}:637"
  }
}

resource "kubernetes_secret" "phpldapadmin_env" {
  metadata {
    name      = "phpldapadmin-env"
    namespace = kubernetes_namespace.openldap.metadata[0].name
  }

  data = {
  }
}

resource "kubernetes_deployment" "phpldapadmin" {
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

          env_from {
            config_map_ref {
              name = kubernetes_config_map.phpldapadmin_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.phpldapadmin_env.metadata[0].name
            }
          }

          #   volume_mount {
          #     mount_path = "/data"
          #     name       = "phpldapadmin-data"
          #   }
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
      kubernetes_config_map.phpldapadmin_env,
      kubernetes_secret.phpldapadmin_env
    ]
  }
}
