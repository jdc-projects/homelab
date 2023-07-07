resource "kubernetes_config_map" "openldap_env" {
  metadata {
    name      = "openldap-env"
    namespace = kubernetes_namespace.openldap.metadata[0].name
  }

  data = {
    LDAP_PORT_NUMBER    = "1389"
    LDAP_ROOT           = "dc=idm,dc=${var.server_base_domain}"
    LDAP_ADMIN_USERNAME = random_password.openldap_admin_username.result
    LDAP_USERS          = "" # need empty values so the generic users aren't created
    LDAP_PASSWORDS      = "" # need empty values so the generic users aren't created
  }
}

resource "kubernetes_secret" "openldap_env" {
  metadata {
    name      = "openldap-env"
    namespace = kubernetes_namespace.openldap.metadata[0].name
  }

  data = {
    LDAP_ADMIN_PASSWORD = random_password.openldap_admin_password.result
  }
}

resource "kubernetes_deployment" "openldap" {
  metadata {
    name      = "openldap"
    namespace = kubernetes_namespace.openldap.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "openldap"
      }
    }

    template {
      metadata {
        labels = {
          app = "openldap"
        }
      }

      spec {
        container {
          image = "bitnami/openldap:2.6.4"
          name  = "openldap"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.openldap_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.openldap_env.metadata[0].name
            }
          }

          #   volume_mount {
          #     mount_path = "/data"
          #     name       = "openldap-data"
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
      kubernetes_config_map.openldap_env,
      kuberkubernetes_secret.openldap_env
    ]
  }
}
