resource "kubernetes_secret" "ocis_config" {
  metadata {
    name      = "ocis-config"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    USERS_LDAP_USER_SUBSTRING_FILTER_TYPE                  = "any"
    USERS_LDAP_BIND_PASSWORD                               = data.terraform_remote_state.openldap.outputs.admin_password
    USERS_IDP_URL                                          = "https://idp.${var.server_base_domain}/realms/${var.server_base_domain}"
    STORAGE_SYSTEM_JWT_SECRET                              = random_password.storage_system_jwt_secret.result
    GROUPS_LDAP_USER_SUBSTRING_FILTER_TYPE                 = "any"
    GROUPS_LDAP_BIND_PASSWORD                              = data.terraform_remote_state.openldap.outputs.admin_password
    GROUPS_IDP_URL                                         = "https://idp.${var.server_base_domain}/realms/${var.server_base_domain}"
    WEB_OIDC_AUTHORITY                                     = "https://idp.${var.server_base_domain}/realms/${var.server_base_domain}"
    WEB_OIDC_CLIENT_ID                                     = "ocis-web"
    WEB_OPTION_CONTEXTHELPERS_READ_MORE                    = "true"
    OCS_IDM_ADDRESS                                        = "https://idp.${var.server_base_domain}/realms/${var.server_base_domain}"
    PROXY_ENABLE_BASIC_AUTH                                = "false"
    PROXY_OIDC_ISSUER                                      = "https://idp.${var.server_base_domain}/realms/${var.server_base_domain}"
    PROXY_OIDC_REWRITE_WELLKNOWN                           = "true"
    PROXY_USER_OIDC_CLAIM                                  = "preferred_username"
    PROXY_USER_CS3_CLAIM                                   = "userid"
    PROXY_OIDC_ACCESS_TOKEN_VERIFY_METHOD                  = "jwt"
    PROXY_OIDC_SKIP_CLIENT_ID_CHECK                        = "true"
    PROXY_TLS                                              = "false"
    PROXY_OIDC_INSECURE                                    = "false"
    PROXY_OIDC_USERINFO_CACHE_STORE                        = "noop"
    THUMBNAILS_TRANSFER_TOKEN                              = random_password.thumbnails_transfer_secret.result
    GRAPH_LDAP_BIND_PASSWORD                               = data.terraform_remote_state.openldap.outputs.admin_password
    GRAPH_LDAP_SERVER_UUID                                 = "true"
    GRAPH_LDAP_SERVER_USE_PASSWORD_MODIFY_EXOP             = "false"
    GRAPH_LDAP_REFINT_ENABLED                              = "false"
    GRAPH_LDAP_GROUP_CREATE_BASE_DN                        = "ou=groups,dc=idm,dc=${var.server_base_domain}"
    NOTIFICATIONS_SMTP_HOST                                = var.smtp_host
    NOTIFICATIONS_SMTP_PORT                                = var.smtp_port
    NOTIFICATIONS_SMTP_SENDER                              = "OCIS <noreply@${var.server_base_domain}>"
    NOTIFICATIONS_SMTP_AUTHENTICATION                      = "login"
    NOTIFICATIONS_SMTP_ENCRYPTION                          = "tls"
    NOTIFICATIONS_SMTP_USERNAME                            = var.smtp_username
    NOTIFICATIONS_SMTP_PASSWORD                            = var.smtp_password

    OCIS_JWT_SECRET = random_password.jwt_secret.result
    OCIS_EXCLUDE_RUN_SERVICES = "idm,idp,auth-basic"
    PROXY_ROLE_ASSIGNMENT_DRIVER = "oidc"
    PROXY_ROLE_ASSIGNMENT_OIDC_CLAIM = "roles"
    OCIS_URL = "https://ocis.${var.server_base_domain}"
    OCIS_MACHINE_AUTH_API_KEY = random_password.machine_auth_api_key.result
    OCIS_SYSTEM_USER_ID = random_uuid.storage_system_user_id.result
    OCIS_SYSTEM_USER_API_KEY = random_password.storage_system_api_key.result
    OCIS_TRANSFER_SECRET = random_password.transfer_secret.result
    STORAGE_USERS_MOUNT_ID = random_uuid.storage_users_mount_id.result
    GATEWAY_STORAGE_USERS_MOUNT_ID = random_uuid.storage_users_mount_id.result
    GRAPH_APPLICATION_ID = random_uuid.graph_application_id.result

    OCIS_LDAP_BIND_DN = "uid=${data.terraform_remote_state.openldap.outputs.admin_username},ou=people,dc=idm,dc=${var.server_base_domain}"
    OCIS_LDAP_CACERT = ""
    OCIS_LDAP_DISABLED_USERS_GROUP_DN = "cn=app_disabled,ou=groups,dc=idm,dc=${var.server_base_domain}"
    OCIS_LDAP_DISABLE_USER_MECHANISM = "group"
    OCIS_LDAP_GROUP_BASE_DN = "ou=groups,dc=idm,dc=${var.server_base_domain}"
    OCIS_LDAP_GROUP_FILTER = ""
    OCIS_LDAP_GROUP_OBJECTCLASS = "groupOfNames"
    OCIS_LDAP_GROUP_SCHEMA_DISPLAYNAME = "cn"
    OCIS_LDAP_GROUP_SCHEMA_GROUPNAME = "cn"
    OCIS_LDAP_GROUP_SCHEMA_ID = "cn"
    OCIS_LDAP_GROUP_SCHEMA_ID_IS_OCTETSTRING = "false"
    OCIS_LDAP_GROUP_SCHEMA_MAIL = "mail"
    OCIS_LDAP_GROUP_SCHEMA_MEMBER = "member"
    OCIS_LDAP_GROUP_SCOPE = "sub"
    OCIS_LDAP_INSECURE = "false"
    OCIS_LDAP_SERVER_WRITE_ENABLED = "false"
    OCIS_LDAP_URI = "ldaps://idm.${var.server_base_domain}"
    OCIS_LDAP_USER_BASE_DN = "ou=people,dc=idm,dc=${var.server_base_domain}"
    OCIS_LDAP_USER_ENABLED_ATTRIBUTE = "ownCloudUserEnabled"
    OCIS_LDAP_USER_FILTER = ""
    OCIS_LDAP_USER_OBJECTCLASS = "inetOrgPerson"
    OCIS_LDAP_USER_SCHEMA_DISPLAYNAME = "displayname"
    OCIS_LDAP_USER_SCHEMA_ID = "uid"
    OCIS_LDAP_USER_SCHEMA_ID_IS_OCTETSTRING = "false"
    OCIS_LDAP_USER_SCHEMA_MAIL = "mail"
    OCIS_LDAP_USER_SCHEMA_USERNAME = "uid"
    # OCIS_LDAP_USER_SCHEMA_USER_TYPE = ""
    OCIS_LDAP_USER_SCOPE = "sub"
  }
}

resource "kubernetes_deployment" "ocis" {
  metadata {
    name      = "ocis"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "ocis"
      }
    }

    template {
      metadata {
        labels = {
          app = "ocis"
        }
      }

      spec {
        container {
          image = "owncloud/ocis:3.0.0"
          name  = "ocis"

          command = ["sh", "-c", "ocis server"]

          env_from {
            secret_ref {
              name = kubernetes_secret.ocis_config.metadata[0].name
            }
          }

          #   volume_mount {
          #     mount_path = "/var/lib/ocis/"
          #     name       = "ocis-data"
          #   }
        }
      }
    }
  }

  timeouts {
    create = "1m"
    update = "1m"
    delete = "1m"
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_secret.ocis_config
    ]
  }
}
