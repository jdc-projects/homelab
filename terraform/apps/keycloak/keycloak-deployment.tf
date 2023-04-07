resource "kubernetes_config_map" "keycloak_configmap" {
  metadata {
    name      = "keycloak"
    namespace = kubernetes_namespace.ldap_namespace.metadata[0].name
  }

  data = {
    KC_CACHE             = "ispn"
    KC_CACHE_STACK       = "kubernetes"
    KC_DB                = "postgres"
    KC_DB_URL_DATABASE   = kubernetes_config_map.keycloak_db_configmap.data.POSTGRES_DB
    KC_DB_URL_HOST       = kubernetes_deployment.keycloak_db_deployment.metadata[0].name
    KC_DB_URL_PORT       = "5432"
    KC_FEATURES          = ""
    KC_FEATURES_DISABLED = "account-api, account2, admin-api, admin-fine-grained-authz, admin2, authorization, ciba, client-policies, client-secret-rotation, declarative-user-profile, docker, dynamic-scopes, fips, impersonation, js-adapter, kerberos, map-storage, openshift-integration, par, preview, recovery-codes, scripts, step-up-authentication, token-exchange, update-email, web-authn"
    KC_HOSTNAME_URL      = "https://idp.${var.base_server_domain}/"
    KC_HTTP_ENABLED      = "true"
    KC_HTTP_PORT         = "8080"
  }
}

resource "kubernetes_secret" "keycloak_secret" {
  metadata {
    name      = "keycloak"
    namespace = kubernetes_namespace.ldap_namespace.metadata[0].name
  }

  data = {
    KEYCLOAK_ADMIN          = random_password.keycloak_admin_username.result
    KEYCLOAK_ADMIN_PASSWORD = random_password.keycloak_admin_password.result
    KC_DB_PASSWORD          = random_password.db_admin_username.result
    KC_DB_USERNAME          = random_password.db_admin_password.result
  }
}

resource "kubernetes_deployment" "keycloak_deployment" {
  metadata {
    name      = "keycloak"
    namespace = kubernetes_namespace.ldap_namespace.metadata[0].name
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
          image = "quay.io/keycloak/keycloak:21.0.2-0"
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

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.keycloak_configmap,
      kubernetes_secret.keycloak_secret
    ]
  }
}
