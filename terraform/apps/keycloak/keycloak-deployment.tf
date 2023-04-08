resource "kubernetes_config_map" "keycloak_configmap" {
  metadata {
    name      = "keycloak"
    namespace = kubernetes_namespace.keycloak_namespace.metadata[0].name
  }

  data = {
    # KC_CACHE                 = "ispn"
    # KC_CACHE_STACK           = "kubernetes"
    KEYCLOAK_DATABASE_VENDOR = "postgresql"
    KEYCLOAK_DATABASE_NAME   = kubernetes_config_map.keycloak_db_configmap.data.POSTGRES_DB
    KEYCLOAK_DATABASE_HOST   = "keycloak-db"
    KEYCLOAK_DATABASE_PORT   = 5432
    # KC_FEATURES              = ""
    # KC_FEATURES_DISABLED     = "account-api, account2, admin-api, admin-fine-grained-authz, admin2, authorization, ciba, client-policies, client-secret-rotation, declarative-user-profile, docker, dynamic-scopes, fips, impersonation, js-adapter, kerberos, map-storage, openshift-integration, par, preview, recovery-codes, scripts, step-up-authentication, token-exchange, update-email, web-authn"
    # KC_HOSTNAME_URL          = "https://idp.${var.server_base_domain}/"
    # KC_HTTP_ENABLED          = "true"
    KEYCLOAK_HTTP_PORT       = "8080"
    # KC_HOSTNAME              = "idp.${var.server_base_domain}"
  }
}

resource "kubernetes_secret" "keycloak_secret" {
  metadata {
    name      = "keycloak"
    namespace = kubernetes_namespace.keycloak_namespace.metadata[0].name
  }

  data = {
    KEYCLOAK_ADMIN_USER        = random_password.keycloak_admin_username.result
    KEYCLOAK_ADMIN_PASSWORD    = random_password.keycloak_admin_password.result
    KEYCLOAK_DATABASE_PASSWORD = random_password.db_admin_username.result
    KEYCLOAK_DATABASE_USER     = random_password.db_admin_password.result
  }
}

resource "kubernetes_deployment" "keycloak_deployment" {
  metadata {
    name      = "keycloak"
    namespace = kubernetes_namespace.keycloak_namespace.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "keycloak"
      }
    }

    template {
      metadata {
        labels = {
          app = "keycloak"
        }
      }

      spec {
        container {
          image = "bitnami/keycloak:21.0.2"
          name  = "keycloak"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.keycloak_configmap.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.keycloak_secret.metadata[0].name
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_deployment.keycloak_db_deployment
  ]

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.keycloak_configmap,
      kubernetes_secret.keycloak_secret
    ]
  }
}
