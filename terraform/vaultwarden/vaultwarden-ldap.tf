resource "kubernetes_config_map" "vaultwarden_ldap_env" {
  metadata {
    name      = "vaultwarden-ldap"
    namespace = kubernetes_namespace.vaultwarden.metadata[0].name
  }

  data = {
    APP_VAULTWARDEN_URL            = "https://vault.${var.server_base_domain}"
    APP_LDAP_HOST                  = "idm.${var.server_base_domain}"
    APP_LDAP_SSL                   = "true"
    APP_LDAP_BIND_DN               = "uid=${data.terraform_remote_state.openldap.outputs.admin_username},ou=people,dc=idm,dc=homelab"
    APP_LDAP_SEARCH_BASE_DN        = "dc=idm,dc=homelab"
    APP_LDAP_SEARCH_FILTER         = "(&(objectClass=inetOrgPerson)(|(memberOf=cn=app_users,ou=groups,dc=idm,dc=homelab)(memberOf=cn=app_admins,ou=groups,dc=idm,dc=homelab)))"
    APP_LDAP_SYNC_INTERVAL_SECONDS = "60"
  }
}

resource "kubernetes_secret" "vaultwarden_ldap_env" {
  metadata {
    name      = "vaultwarden-ldap"
    namespace = kubernetes_namespace.vaultwarden.metadata[0].name
  }

  data = {
    APP_VAULTWARDEN_ADMIN_TOKEN = random_password.vaultwarden_admin_token.result
    APP_LDAP_BIND_PASSWORD      = data.terraform_remote_state.openldap.outputs.admin_password
  }
}

resource "kubernetes_deployment" "vaultwarden_ldap_deployment" {
  metadata {
    name      = "vaultwarden-ldap"
    namespace = kubernetes_namespace.vaultwarden.metadata[0].name
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
          image = "vividboarder/vaultwarden_ldap:2.0.2"
          name  = "vaultwarden-ldap"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.vaultwarden_ldap_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.vaultwarden_ldap_env.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }

            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.vaultwarden_ldap_env,
      kubernetes_secret.vaultwarden_ldap_env
    ]
  }

  depends_on = [kubernetes_deployment.vaultwarden_deployment]
}
