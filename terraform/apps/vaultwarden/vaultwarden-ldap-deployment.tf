resource "kubernetes_config_map" "vaultwarden_ldap_configmap" {
  metadata {
    name      = "vaultwarden-ldap"
    namespace = kubernetes_namespace.vaultwarden_namespace.metadata[0].name
  }

  data = {
    APP_VAULTWARDEN_URL            = "vault.${var.server_base_domain}"
    APP_LDAP_HOST                  = "idm.${var.server_base_domain}"
    APP_LDAP_SSL                   = "true"
    APP_LDAP_BIND_DN               = "uid=admin,ou=people,dc=idm,dc=${var.server_base_domain}"
    APP_LDAP_SEARCH_BASE_DN        = "dc=idm,dc=${var.server_base_domain}"
    APP_LDAP_SEARCH_FILTER         = "(&(objectClass=person)(memberOf=uid=vaultwarden,ou=groups,dc=idm,dc=${var.server_base_domain}))"
    APP_LDAP_SYNC_INTERVAL_SECONDS = "60"
  }
}

resource "kubernetes_secret" "vaultwarden_ldap_secret" {
  metadata {
    name      = "vaultwarden-ldap"
    namespace = kubernetes_namespace.vaultwarden_namespace.metadata[0].name
  }

  data = {
    APP_VAULTWARDEN_ADMIN_TOKEN = random_password.vaultwarden_admin_token.result
    APP_LDAP_BIND_PASSWORD      = var.lldap_admin_password
  }
}

resource "kubernetes_deployment" "vaultwarden_ldap_deployment" {
  metadata {
    name      = "vaultwarden-ldap"
    namespace = kubernetes_namespace.vaultwarden_namespace.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "vaultwarden-ldap"
      }
    }

    template {
      metadata {
        labels = {
          app = "vaultwarden-ldap"
        }
      }

      spec {
        container {
          image = "vividboarder/vaultwarden_ldap:1.0.0-alpine"
          name  = "vaultwarden-ldap"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.vaultwarden_ldap_configmap.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.vaultwarden_ldap_secret.metadata[0].name
            }
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.vaultwarden_ldap_configmap
    ]
  }
}
