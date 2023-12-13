locals {
  harbor_db_instances = 2
}

resource "kubernetes_manifest" "harbor_db" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"

    metadata = {
      name      = "harbor-db"
      namespace = kubernetes_namespace.harbor.metadata[0].name
    }

    spec = {
      # https://github.com/cloudnative-pg/postgres-containers/pkgs/container/postgresql
      imageName = "ghcr.io/cloudnative-pg/postgresql:16.1-7"

      instances = local.harbor_db_instances

      bootstrap = {
        initdb = {
          database = "harbor"
          owner    = random_password.harbor_db_username.result
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
      "status.readyInstances" = local.harbor_db_instances
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
