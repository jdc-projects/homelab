resource "kubernetes_config_map" "ldap_user_manager_env" {
  metadata {
    name      = "ldap-user-manager-env"
    namespace = kubernetes_namespace.openldap.metadata[0].name
  }

  data = {
    LDAP_URI                           = "ldaps://idm.${var.server_base_domain}"
    LDAP_BASE_DN                       = "dc=idm,dc=homelab"
    LDAP_ADMIN_BIND_DN                 = "cn=${random_password.openldap_admin_username.result},dc=idm,dc=homelab"
    LDAP_ADMINS_GROUP                  = data.keycloak_group.system_admins.name
    SERVER_HOSTNAME                    = "idm3.${var.server_base_domain}"
    SERVER_PORT                        = "80"
    NO_HTTPS                           = "TRUE"
    ORGANISATION_NAME                  = var.server_base_domain
    SITE_NAME                          = "${var.server_base_domain} Account Management"
    LDAP_REQUIRE_STARTTLS              = "FALSE"
    FORCE_RFC2307BIS                   = "TRUE"
    DEFAULT_USER_GROUP                 = "app_guests"
    USERNAME_FORMAT                    = "{first_name}.{last_name}"
    SMTP_HOSTNAME                      = var.smtp_host
    SMTP_HOST_PORT                     = var.smtp_port
    SMTP_USERNAME                      = var.smtp_username
    SMTP_PASSWORD                      = var.smtp_password
    SMTP_USE_TLS                       = "TRUE"
    EMAIL_FROM_ADDRESS                 = "noreply@${var.server_base_domain}"
    EMAIL_FROM_NAME                    = "LDAP User Manager ${var.server_base_domain}"
    LDAP_GROUP_MEMBERSHIP_ATTRIBUTE    = "member"
    LDAP_ACCOUNT_ADDITIONAL_ATTRIBUTES = "displayName:Display Name"
  }
}

resource "kubernetes_secret" "ldap_user_manager_env" {
  metadata {
    name      = "ldap-user-manager-env"
    namespace = kubernetes_namespace.openldap.metadata[0].name
  }

  data = {
    LDAP_ADMIN_BIND_PWD = random_password.openldap_admin_password.result
  }
}

resource "kubernetes_deployment" "ldap_user_manager" {
  metadata {
    name      = "ldap-user-manager"
    namespace = kubernetes_namespace.openldap.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "ldap-user-manager"
      }
    }

    template {
      metadata {
        labels = {
          app = "ldap-user-manager"
        }
      }

      spec {
        container {
          image = "wheelybird/ldap-user-manager:v1.11"
          name  = "phpldapadmin"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.ldap_user_manager_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.ldap_user_manager_env.metadata[0].name
            }
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.ldap_user_manager_env,
      kubernetes_secret.ldap_user_manager_env
    ]
  }
}
