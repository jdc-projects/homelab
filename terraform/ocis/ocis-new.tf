resource "kubernetes_secret" "ocis_config" {
  metadata {
    name      = "ocis-config"
    namespace = kubernetes_namespace.ocis.metadata[0].name
  }

  data = {
    OCIS_LOG_LEVEL        = "debug"
    OCIS_LOG_PRETTY       = "true"
    OCIS_LOG_COLOR        = "true"
    OCIS_URL              = "https://ocis.${var.server_base_domain}"
    IDM_CREATE_DEMO_USERS = "true"
    PROXY_TLS             = "false"
    # OCIS_OIDC_ISSUER                  = data.terraform_remote_state.keycloak_config.outputs.keycloak_hostname_url
    # WEB_OIDC_METADATA_URL             = "${data.terraform_remote_state.keycloak_config.outputs.keycloak_hostname_url}/realms/${data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id}/.well-known/openid-configuration"
    # OCIS_OIDC_CLIENT_ID               = keycloak_openid_client.ocis_web_client.client_id
    # WEB_OIDC_POST_LOGOUT_REDIRECT_URI = "https://ocis.${var.server_base_domain}"
    # OCIS_LDAP_SERVER_WRITE_ENABLED    = "false"
    # OCIS_LDAP_URI                     = "ldaps://idm.${var.server_base_domain}"
    # OCIS_LDAP_BIND_DN                 = "uid=admin,ou=people,dc=idm,dc=${var.server_base_domain}"
    # OCIS_LDAP_BIND_PASSWORD           = data.terraform_remote_state.lldap.outputs.lldap_admin_password
    # OCIS_LDAP_USER_BASE_DN            = "ou=people,dc=idm,dc=${var.server_base_domain}"
    # OCIS_LDAP_USER_SCHEMA_ID          = "uid"
    # OCIS_LDAP_USER_OBJECTCLASS        = "person"
    # OCIS_LDAP_GROUP_SCHEMA_ID         = "uid"
    # OCIS_LDAP_GROUP_BASE_DN           = "ou=groups,dc=idm,dc=${var.server_base_domain}"
    # PROXY_ROLE_ASSIGNMENT_DRIVER      = "oidc"
    # PROXY_TLS                         = "false"
    # PROXY_USER_OIDC_CLAIM             = "preferred_username"
    # PROXY_USER_CS3_CLAIM              = "userid"
    # PROXY_ENABLE_BASIC_AUTH           = "false"
    # OCIS_JWT_SECRET                   = random_password.jwt_secret.result
    # OCIS_TRANSFER_SECRET              = random_password.transfer_secret.result
    # OCIS_MACHINE_AUTH_API_KEY         = random_password.machine_auth_api_key.result
    # OCIS_SYSTEM_USER_API_KEY          = random_password.system_user_api_key.result
    # OCIS_SYSTEM_USER_ID               = random_uuid.system_user_id.result
    # STORAGE_USERS_MOUNT_ID            = random_uuid.storage_users_mount_id.result
    # IDM_SVC_PASSWORD                  = random_password.idm_svc_password.result
    # IDM_REVASVC_PASSWORD              = random_password.idm_revasvc_password.result
    # IDM_IDPSVC_PASSWORD               = random_password.idm_idpsvc_password.result
    # OCIS_EXCLUDE_RUN_SERVICES         = "idp"
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
