resource "kubernetes_secret" "ocis_config" {
  metadata {
    name      = "ocis-config"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    OCIS_LOG_LEVEL                    = "debug"
    OCIS_LOG_PRETTY                   = "true"
    OCIS_LOG_COLOR                    = "true"
    OCIS_URL                          = "https://ocis.${var.server_base_domain}"
    IDM_CREATE_DEMO_USERS             = "true"
    PROXY_TLS                         = "false"
    OCIS_OIDC_ISSUER                  = data.terraform_remote_state.keycloak_config.outputs.keycloak_hostname_url
    WEB_OIDC_METADATA_URL             = "${data.terraform_remote_state.keycloak_config.outputs.keycloak_hostname_url}/realms/${data.terraform_remote_state.keycloak_config.outputs.server_base_domain_realm_id}/.well-known/openid-configuration"
    OCIS_OIDC_CLIENT_ID               = keycloak_openid_client.ocis_web.client_id
    WEB_OIDC_POST_LOGOUT_REDIRECT_URI = "https://ocis.${var.server_base_domain}"
    OCIS_LDAP_SERVER_WRITE_ENABLED    = "false"
    OCIS_LDAP_URI                     = "ldaps://idm.${var.server_base_domain}"
    OCIS_LDAP_BIND_DN                 = "uid=${data.terraform_remote_state.openldap.outputs.admin_username},ou=people,dc=idm,dc=${var.server_base_domain}"
    OCIS_LDAP_BIND_PASSWORD           = data.terraform_remote_state.openldap.outputs.admin_password
    OCIS_LDAP_USER_BASE_DN            = "ou=people,dc=idm,dc=${var.server_base_domain}"
    OCIS_LDAP_USER_SCHEMA_ID          = "uid"
    OCIS_LDAP_USER_OBJECTCLASS        = "inetOrgPerson"
    OCIS_LDAP_GROUP_SCHEMA_ID         = "cn"
    OCIS_LDAP_GROUP_BASE_DN           = "ou=groups,dc=idm,dc=${var.server_base_domain}"
    PROXY_ROLE_ASSIGNMENT_DRIVER      = "oidc"
    PROXY_USER_OIDC_CLAIM             = "preferred_username"
    PROXY_USER_CS3_CLAIM              = "userid"
    PROXY_ENABLE_BASIC_AUTH           = "false"
    OCIS_JWT_SECRET                   = random_password.jwt_secret.result
    OCIS_MACHINE_AUTH_API_KEY         = random_password.machine_auth_api_key.result
    OCIS_SYSTEM_USER_ID               = random_uuid.storage_system_user_id.result
    OCIS_SYSTEM_USER_API_KEY          = random_password.storage_system_api_key.result
    # STORAGE_SYSTEM_JWT_SECRET = random_password.storage_system_jwt_secret.result # shouldn't be needed
    OCIS_TRANSFER_SECRET      = random_password.transfer_secret.result
    THUMBNAILS_TRANSFER_TOKEN = random_password.thumbnails_transfer_secret.result
    # STORAGE_USERS_MOUNT_ID            = random_uuid.storage_users_mount_id.result
    OCIS_EXCLUDE_RUN_SERVICES = "idm,idp,auth-basic"
    OCIS_ADMIN_USER_ID = "PLACEHOLDER_VALUE"
    STORAGE_USERS_MOUNT_ID = "REPLACE_ME"
    LDAP_BIND_PASSWORD = "WHY_DO_I_NEED_THIS"
    GRAPH_APPLICATION_ID = "REPLACE_ME"
    GATEWAY_STORAGE_USERS_MOUNT_ID = "REPLACE_ME"
    OCIS_GRPC_CLIENT_TLS_MODE = "off"
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
