
resource "kubernetes_config_map" "ocis_configmap" {
  metadata {
    name      = "ocis"
    namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
  }

  data = {
    # IDM_CREATE_DEMO_USERS = "true"
    OCIS_URL       = "https://owncloud.${var.server_base_domain}"
    OCIS_LOG_LEVEL = "debug"
    # PROXY_TLS                     = "false"
    OCIS_INSECURE = "true"
    # PROXY_ENABLE_BASIC_AUTH       = "true"
    # AUTH_BASIC_AUTH_MANAGER       = "ldap"
    # AUTH_BASIC_LDAP_URI           = "ldaps://idm.${var.server_base_domain}"
    # AUTH_BASIC_LDAP_INSECURE      = "false"
    # AUTH_BASIC_LDAP_BIND_DN       = "uid=admin,dc=idm,dc=${var.server_base_domain}"
    # AUTH_BASIC_LDAP_USER_BASE_DN  = "ou=people,dc=idm,dc=${var.server_base_domain}"
    # AUTH_BASIC_LDAP_GROUP_BASE_DN = "ou=groups,dc=idm,dc=${var.server_base_domain}"
    # OCIS_ADMIN_USER_ID            = "jack"
    # OCIS_RUN_SERVICES               = "app-registry,app-provider,audit,auth-basic,auth-machine,frontend,gateway,graph,groups,idp,nats,notifications,ocdav,ocs,proxy,search,settings,sharing,storage-system,storage-publiclink,storage-shares,storage-users,store,thumbnails,users,web,webdav"
  }
}

resource "random_password" "ocis_jwt_secret" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "ocis_transfer_secret" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "ocis_machine_auth_api_key" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_secret" "ocis_secret" {
  metadata {
    name      = "ocis"
    namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
  }

  data = {
    # AUTH_BASIC_LDAP_BIND_PASSWORD = var.lldap_admin_password
    # OCIS_JWT_SECRET               = random_password.ocis_jwt_secret.result
    # STORAGE_TRANSFER_SECRET       = random_password.ocis_transfer_secret.result
    # OCIS_MACHINE_AUTH_API_KEY     = random_password.ocis_machine_auth_api_key.result
  }
}

resource "kubernetes_deployment" "ocis_deployment" {
  metadata {
    name      = "ocis"
    namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
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
            config_map_ref {
              name = kubernetes_config_map.ocis_configmap.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.ocis_secret.metadata[0].name
            }
          }

          # volume_mount {
          #   mount_path = "/var/lib/ocis"
          #   name       = "ocis-data"
          # }
        }

        # volume {
        #   name = "ocis-data"

        #   host_path {
        #     path = truenas_dataset.ocis_dataset.mount_point
        #   }
        # }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.ocis_configmap,
      kubernetes_secret.ocis_secret
    ]
  }
}
