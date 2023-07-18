resource "kubernetes_secret" "ocis_config" {
  metadata {
    name      = "ocis-config"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    GATEWAY_STORAGE_USERS_MOUNT_ID                         = "3081f183-2e58-4f6f-8bb1-900a4152058a" # *****
    OCIS_TRANSFER_SECRET                                   = random_password.transfer_secret.result
    OCIS_LDAP_SERVER_WRITE_ENABLED                         = "false"
    FRONTEND_READONLY_USER_ATTRIBUTES                      = ""
    FRONTEND_APP_HANDLER_INSECURE                          = "false"
    FRONTEND_ARCHIVER_INSECURE                             = "false"
    FRONTEND_OCS_PUBLIC_WRITEABLE_SHARE_MUST_HAVE_PASSWORD = "false"
    FRONTEND_SEARCH_MIN_LENGTH                             = "3"
    FRONTEND_ENABLE_RESHARING                              = "true"
    FRONTEND_ARCHIVER_MAX_SIZE                             = "1.073741824e+09"
    FRONTEND_ARCHIVER_MAX_NUM_FILES                        = "10000"
    FRONTEND_OCS_STAT_CACHE_STORE                          = "noop"
    OCIS_EDITION                                           = "Community"
    FRONTEND_MACHINE_AUTH_API_KEY                          = random_password.machine_auth_api_key.result
    OCIS_TRANSFER_SECRET                                   = random_password.transfer_secret.result
    USERS_LDAP_INSECURE                                    = "false"
    USERS_LDAP_USER_BASE_DN                                = "ou=people,dc=idm,dc=${var.server_base_domain}"
    USERS_LDAP_GROUP_BASE_DN                               = "ou=groups,dc=idm,dc=${var.server_base_domain}"
    USERS_LDAP_USER_SCOPE                                  = "sub"
    USERS_LDAP_GROUP_SCOPE                                 = "sub"
    USERS_LDAP_USER_SUBSTRING_FILTER_TYPE                  = "any"
    USERS_LDAP_USER_FILTER                                 = ""
    USERS_LDAP_GROUP_FILTER                                = ""
    USERS_LDAP_USER_OBJECTCLASS                            = "inetOrgPerson"
    USERS_LDAP_GROUP_OBJECTCLASS                           = "groupOfNames"
    USERS_LDAP_USER_SCHEMA_ID                              = "uid"
    USERS_LDAP_GROUP_SCHEMA_ID                             = "cn"
    USERS_LDAP_USER_SCHEMA_ID_IS_OCTETSTRING               = "false"
    USERS_LDAP_GROUP_SCHEMA_ID_IS_OCTETSTRING              = "false"
    USERS_LDAP_USER_SCHEMA_MAIL                            = "mail"
    USERS_LDAP_GROUP_SCHEMA_MAIL                           = "mail"
    USERS_LDAP_USER_SCHEMA_DISPLAYNAME                     = "displayname"
    USERS_LDAP_GROUP_SCHEMA_DISPLAYNAME                    = "cn"
    USERS_LDAP_USER_SCHEMA_USERNAME                        = "uid"
    USERS_LDAP_USER_TYPE_ATTRIBUTE                         = "ownCloudUserType"
    USERS_LDAP_GROUP_SCHEMA_GROUPNAME                      = "cn"
    USERS_LDAP_GROUP_SCHEMA_MEMBER                         = "member"
    USERS_LDAP_USER_ENABLED_ATTRIBUTE                      = "ownCloudUserEnabled"
    USERS_LDAP_DISABLE_USER_MECHANISM                      = "group"
    USERS_LDAP_DISABLED_USERS_GROUP_DN                     = "cn=app_disabled,ou=groups,dc=idm,dc=${var.server_base_domain}"
    USERS_LDAP_URI                                         = "ldaps://idm.${var.server_base_domain}"
    USERS_LDAP_CACERT                                      = ""
    USERS_LDAP_BIND_DN                                     = "uid=${data.terraform_remote_state.openldap.outputs.admin_username},ou=people,dc=idm,dc=${var.server_base_domain}"
    USERS_LDAP_BIND_PASSWORD                               = data.terraform_remote_state.openldap.outputs.admin_password
    USERS_IDP_URL                                          = "https://idp.${var.server_base_domain}/realms/${var.server_base_domain}"
    OCIS_SYSTEM_USER_API_KEY                               = random_uuid.storage_system_user_id.result
    OCIS_SYSTEM_USER_ID                                    = random_password.storage_system_api_key.result
    STORAGE_SYSTEM_JWT_SECRET                              = random_password.storage_system_jwt_secret.result
    OCIS_SYSTEM_USER_API_KEY                               = random_uuid.storage_system_user_id.result
    OCIS_SYSTEM_USER_ID                                    = random_password.storage_system_api_key.result
    AUTH_MACHINE_API_KEY                                   = random_password.machine_auth_api_key.result
    GROUPS_LDAP_INSECURE                                   = "false"
    GROUPS_LDAP_USER_BASE_DN                               = "ou=people,dc=idm,dc=${var.server_base_domain}"
    GROUPS_LDAP_GROUP_BASE_DN                              = "ou=groups,dc=idm,dc=${var.server_base_domain}"
    GROUPS_LDAP_USER_SCOPE                                 = "sub"
    GROUPS_LDAP_GROUP_SCOPE                                = "sub"
    GROUPS_LDAP_USER_SUBSTRING_FILTER_TYPE                 = "any"
    GROUPS_LDAP_USER_FILTER                                = ""
    GROUPS_LDAP_GROUP_FILTER                               = ""
    GROUPS_LDAP_USER_OBJECTCLASS                           = "inetOrgPerson"
    GROUPS_LDAP_GROUP_OBJECTCLASS                          = "groupOfNames"
    GROUPS_LDAP_USER_SCHEMA_ID                             = "uid"
    GROUPS_LDAP_GROUP_SCHEMA_ID                            = "cn"
    GROUPS_LDAP_USER_SCHEMA_ID_IS_OCTETSTRING              = "false"
    GROUPS_LDAP_GROUP_SCHEMA_ID_IS_OCTETSTRING             = "false"
    GROUPS_LDAP_USER_SCHEMA_MAIL                           = "mail"
    GROUPS_LDAP_GROUP_SCHEMA_MAIL                          = "mail"
    GROUPS_LDAP_USER_SCHEMA_DISPLAYNAME                    = "displayname"
    GROUPS_LDAP_GROUP_SCHEMA_DISPLAYNAME                   = "cn"
    GROUPS_LDAP_USER_SCHEMA_USERNAME                       = "uid"
    GROUPS_LDAP_GROUP_SCHEMA_GROUPNAME                     = "cn"
    GROUPS_LDAP_GROUP_SCHEMA_MEMBER                        = "member"
    GROUPS_LDAP_URI                                        = "ldaps://idm.${var.server_base_domain}"
    GROUPS_LDAP_CACERT                                     = ""
    GROUPS_LDAP_BIND_DN                                    = "uid=${data.terraform_remote_state.openldap.outputs.admin_username},ou=people,dc=idm,dc=${var.server_base_domain}"
    GROUPS_LDAP_BIND_PASSWORD                              = data.terraform_remote_state.openldap.outputs.admin_password
    GROUPS_IDP_URL                                         = "https://idp.${var.server_base_domain}/realms/${var.server_base_domain}"
    WEB_OIDC_AUTHORITY                                     = "https://idp.${var.server_base_domain}/realms/${var.server_base_domain}"
    WEB_OIDC_CLIENT_ID                                     = "ocis-web"
    WEB_OPTION_CONTEXTHELPERS_READ_MORE                    = "true"
    SHARING_USER_JSONCS3_SYSTEM_USER_API_KEY               = random_uuid.storage_system_user_id.result
    SHARING_USER_JSONCS3_SYSTEM_USER_ID                    = random_password.storage_system_api_key.result
    SHARING_PUBLIC_JSONCS3_SYSTEM_USER_API_KEY             = random_uuid.storage_system_user_id.result
    OCS_IDM_ADDRESS                                        = "https://idp.${var.server_base_domain}/realms/${var.server_base_domain}"
    OCS_MACHINE_AUTH_API_KEY                               = random_password.machine_auth_api_key.result
    USERLOG_MACHINE_AUTH_API_KEY                           = random_password.machine_auth_api_key.result
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
    PROXY_MACHINE_AUTH_API_KEY                             = random_password.machine_auth_api_key.result
    OCIS_MACHINE_AUTH_API_KEY                              = random_password.machine_auth_api_key.result
    STORAGE_USERS_MOUNT_ID                                 = "3081f183-2e58-4f6f-8bb1-900a4152058a" # *****
    OCIS_TRANSFER_SECRET                                   = random_password.transfer_secret.result
    SEARCH_MACHINE_AUTH_API_KEY                            = random_password.machine_auth_api_key.result
    THUMBNAILS_TRANSFER_TOKEN                              = random_password.thumbnails_transfer_secret.result
    OCIS_EDITION                                           = "Community"
    OCDAV_MACHINE_AUTH_API_KEY                             = random_password.machine_auth_api_key.result
    GRAPH_LDAP_URI                                         = "ldaps://idm.${var.server_base_domain}"
    GRAPH_LDAP_BIND_DN                                     = "uid=${data.terraform_remote_state.openldap.outputs.admin_username},ou=people,dc=idm,dc=${var.server_base_domain}"
    GRAPH_LDAP_BIND_PASSWORD                               = data.terraform_remote_state.openldap.outputs.admin_password
    GRAPH_LDAP_SERVER_WRITE_ENABLED                        = "false"
    GRAPH_LDAP_CACERT                                      = ""
    GRAPH_LDAP_INSECURE                                    = "false"
    GRAPH_LDAP_SERVER_UUID                                 = "true"
    GRAPH_LDAP_SERVER_USE_PASSWORD_MODIFY_EXOP             = "false"
    GRAPH_LDAP_REFINT_ENABLED                              = "false"
    GRAPH_LDAP_USER_BASE_DN                                = "ou=people,dc=idm,dc=${var.server_base_domain}"
    GRAPH_LDAP_GROUP_BASE_DN                               = "ou=groups,dc=idm,dc=${var.server_base_domain}"
    GRAPH_LDAP_GROUP_CREATE_BASE_DN                        = "ou=groups,dc=idm,dc=${var.server_base_domain}"
    GRAPH_LDAP_USER_SCOPE                                  = "sub"
    GRAPH_LDAP_GROUP_SEARCH_SCOPE                          = "sub"
    GRAPH_LDAP_USER_FILTER                                 = ""
    GRAPH_LDAP_GROUP_FILTER                                = ""
    GRAPH_LDAP_USER_OBJECTCLASS                            = "inetOrgPerson"
    GRAPH_LDAP_GROUP_OBJECTCLASS                           = "groupOfNames"
    GRAPH_LDAP_USER_UID_ATTRIBUTE                          = "uid"
    GRAPH_LDAP_GROUP_ID_ATTRIBUTE                          = "cn"
    GRAPH_LDAP_USER_EMAIL_ATTRIBUTE                        = "mail"
    GRAPH_LDAP_USER_DISPLAYNAME_ATTRIBUTE                  = "displayname"
    GRAPH_LDAP_USER_NAME_ATTRIBUTE                         = "uid"
    GRAPH_LDAP_USER_TYPE_ATTRIBUTE                         = "ownCloudUserType"
    GRAPH_LDAP_GROUP_NAME_ATTRIBUTE                        = "cn"
    GRAPH_LDAP_USER_SCHEMA_ID_IS_OCTETSTRING               = "false"
    GRAPH_LDAP_GROUP_SCHEMA_ID_IS_OCTETSTRING              = "false"
    GRAPH_USER_ENABLED_ATTRIBUTE                           = "ownCloudUserEnabled"
    GRAPH_DISABLE_USER_MECHANISM                           = "group"
    GRAPH_DISABLED_USERS_GROUP_DN                          = "cn=app_disabled,ou=groups,dc=idm,dc=${var.server_base_domain}"
    GRAPH_APPLICATION_ID                                   = "1a194158-7bfe-4375-a00f-4db4a903afa4" # *****
    USERLOG_MACHINE_AUTH_API_KEY                           = random_password.machine_auth_api_key.result
    NOTIFICATIONS_SMTP_HOST                                = var.smtp_host
    NOTIFICATIONS_SMTP_PORT                                = var.smtp_port
    NOTIFICATIONS_SMTP_SENDER                              = "OCIS <noreply@${var.server_base_domain}>"
    NOTIFICATIONS_SMTP_AUTHENTICATION                      = "login"
    NOTIFICATIONS_SMTP_ENCRYPTION                          = "tls"
    NOTIFICATIONS_SMTP_USERNAME                            = var.smtp_username
    NOTIFICATIONS_SMTP_PASSWORD                            = var.smtp_password
    NOTIFICATIONS_MACHINE_AUTH_API_KEY                     = random_password.machine_auth_api_key.result

    OCIS_JWT_SECRET = random_password.jwt_secret.result
    OCIS_EXCLUDE_RUN_SERVICES = "idm,idp,auth-basic"
    PROXY_ROLE_ASSIGNMENT_DRIVER = "oidc"
    PROXY_ROLE_ASSIGNMENT_OIDC_CLAIM = "roles"
    OCIS_URL = "https://ocis.${var.server_base_domain}"
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
