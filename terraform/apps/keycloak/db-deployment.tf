resource "kubernetes_config_map" "keycloak_db_configmap" {
  metadata {
    name      = "keycloak-db"
    namespace = kubernetes_namespace.keycloak_namespace.metadata[0].name
  }

  data = {
    POSTGRES_DB = "keycloak"
    PGDATA      = "/var/lib/postgresql/data"
  }
}

resource "kubernetes_secret" "keycloak_db_secret" {
  metadata {
    name      = "keycloak-db"
    namespace = kubernetes_namespace.keycloak_namespace.metadata[0].name
  }

  data = {
    POSTGRES_PASSWORD = random_password.db_admin_username.result
    POSTGRES_USER     = random_password.db_admin_password.result
  }
}

resource "kubernetes_deployment" "keycloak_db_deployment" {
  metadata {
    name      = "keycloak-db"
    namespace = kubernetes_namespace.keycloak_namespace.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "keycloak-db"
      }
    }

    template {
      metadata {
        labels = {
          app = "keycloak-db"
        }
      }

      spec {
        container {
          image = "postgres:15.2-alpine"
          name  = "keycloak-db"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.keycloak_db_configmap.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.keycloak_db_secret.metadata[0].name
            }
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.keycloak_db_configmap,
      kubernetes_secret.keycloak_db_secret
    ]
  }
}
