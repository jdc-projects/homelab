resource "kubernetes_config_map" "lldap_configmap" {
  metadata {
    name      = "lldap"
    namespace = kubernetes_namespace.ldap_namespace.metadata[0].name
  }

  data = {
    LLDAP_LDAP_HOST       = "0.0.0.0"
    LLDAP_LDAP_PORT       = "389"
    LLDAP_HTTP_HOST       = "0.0.0.0"
    LLDAP_HTTP_PORT       = "80"
    LLDAP_HTTP_URL        = "https://idm.${var.server_base_domain}"
    LLDAP_LDAP_BASE_DN    = "dc=idm,dc=${var.server_base_domain}"
    LLDAP_LDAP_USER_DN    = "admin"
    LLDAP_LDAP_USER_EMAIL = "admin@jack-chapman.co.uk"
  }
}

resource "random_password" "lldap_jwt_secret" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_secret" "lldap_secret" {
  metadata {
    name      = "lldap"
    namespace = kubernetes_namespace.ldap_namespace.metadata[0].name
  }

  data = {
    LLDAP_JWT_SECRET     = random_password.lldap_jwt_secret.result
    LLDAP_LDAP_USER_PASS = var.lldap_admin_password
  }
}

resource "kubernetes_deployment" "lldap_deployment" {
  metadata {
    name      = "lldap"
    namespace = kubernetes_namespace.ldap_namespace.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "lldap"
      }
    }

    template {
      metadata {
        labels = {
          app = "lldap"
        }
      }

      spec {
        container {
          image = "nitnelave/lldap:v0.4.2-alpine"
          name  = "lldap"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.lldap_configmap.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.lldap_secret.metadata[0].name
            }
          }

          volume_mount {
            mount_path = "/data"
            name       = "lldap-data"
          }
        }

        volume {
          name = "lldap-data"

          host_path {
            path = truenas_dataset.lldap_dataset.mount_point
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.lldap_configmap,
      kubernetes_secret.lldap_secret
    ]
  }
}
