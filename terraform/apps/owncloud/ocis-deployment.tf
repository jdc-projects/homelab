
resource "kubernetes_config_map" "ocis_configmap" {
  metadata {
    name      = "ocis"
    namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
  }

  data = {
    LDAP_URI                        = "ldaps://idm.${var.server_base_domain}"
    LDAP_INSECURE                   = "false"
    LDAP_BIND_DN                    = "uid=admin,dc=idm,dc=${var.server_base_domain}"
    LDAP_GROUP_BASE_DN              = "ou=groups,dc=idm,dc=${var.server_base_domain}"
    LDAP_GROUP_FILTER               = "" # *****
    LDAP_GROUP_OBJECTCLASS          = "" # *****
    LDAP_USER_BASE_DN               = "ou=people,dc=idm,dc=${var.server_base_domain}"
    LDAP_USER_FILTER                = "" # *****
    LDAP_USER_OBJECTCLASS           = "" # *****
    LDAP_LOGIN_ATTRIBUTES           = "uid"
    OCIS_ADMIN_USER_ID              = "" # *****
    IDP_LDAP_LOGIN_ATTRIBUTE        = "" # *****
    IDP_LDAP_UUID_ATTRIBUTE         = "" # *****
    IDP_LDAP_UUID_ATTRIBUTE_TYPE    = "" # *****
    GRAPH_LDAP_SERVER_WRITE_ENABLED = "false"
    GRAPH_LDAP_REFINT_ENABLED       = "false"
    OCIS_RUN_SERVICES               = "app-registry,app-provider,audit,auth-basic,auth-machine,frontend,gateway,graph,groups,idp,nats,notifications,ocdav,ocs,proxy,search,settings,sharing,storage-system,storage-publiclink,storage-shares,storage-users,store,thumbnails,users,web,webdav"
    OCIS_URL                        = "https://owncloud.${var.server_base_domain}"
    OCIS_LOG_LEVEL                  = "info"
    # OCIS_LOG_COLOR                  = ""
    PROXY_TLS               = "false" # *****
    OCIS_INSECURE           = ""      # *****
    PROXY_ENABLE_BASIC_AUTH = ""      # *****
  }
}

resource "kubernetes_secret" "ocis_secret" {
  metadata {
    name      = "ocis"
    namespace = kubernetes_namespace.ocis_namespace.metadata[0].name
  }

  data = {
    LDAP_BIND_PASSWORD = var.lldap_admin_password
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
          image = "owncloud/ocis:2.0.0"
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

          volume_mount {
            mount_path = "/var/lib/ocis"
            name       = "ocis-data"
          }
        }

        volume {
          name = "ocis-data"

          host_path {
            path = truenas_dataset.ocis_dataset.mount_point
          }
        }
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
