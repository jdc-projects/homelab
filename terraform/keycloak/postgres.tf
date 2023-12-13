resource "kubernetes_manifest" "keycloak_db" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"

    metadata = {
      name      = "keycloak-db"
      namespace = kubernetes_namespace.keycloak.metadata[0].name
    }

    spec = {
      # https://github.com/cloudnative-pg/postgres-containers/pkgs/container/postgresql
      imageName = "ghcr.io/cloudnative-pg/postgresql:16.1-7"

      instances = local.keycloak_db_instances

      bootstrap = {
        initdb = {
          database = "keycloak"
          owner    = random_password.keycloak_db_username.result
          secret = {
            name = kubernetes_secret.db_credentials.metadata[0].name
          }
        }
      }

      storage = {
        size = "5Gi"
      }

      resources = {
        requests = {
          cpu    = "500m"
          memory = "1Gi"
        }

        limits = {
          cpu    = "1"
          memory = "2Gi"
        }
      }

      primaryUpdateStrategy = "unsupervised"
      primaryUpdateMethod   = "switchover"

      logLevel = "info"
    }
  }

  wait {
    fields = {
      "status.phase"          = "Cluster in healthy state"
      "status.readyInstances" = local.keycloak_db_instances
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
