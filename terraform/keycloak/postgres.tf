module "sg_instance_sizes" {
  source = "../modules/sg-instance-sizes"

  namespace = kubernetes_namespace.keycloak.metadata[0].name
}

resource "kubernetes_manifest" "sg_distributed_logs" {
  manifest = {
    apiVersion = "stackgres.io/v1"
    kind       = "SGDistributedLogs"

    metadata = {
      name      = "keycloak-db"
      namespace = kubernetes_namespace.keycloak.metadata[0].name
    }

    spec = {
      persistentVolume = {
        size = "10Gi"
      }

      resources = {
        disableResourcesRequestsSplitFromTotal = "true"
      }
    }
  }
}

resource "kubernetes_manifest" "sg_cluster" {
  manifest = {
    apiVersion = "stackgres.io/v1"
    kind       = "SGCluster"

    metadata = {
      name      = "keycloak-db"
      namespace = kubernetes_namespace.keycloak.metadata[0].name
    }

    spec = {
      postgres = {
        version = "16"
      }

      instances = 1

      sgInstanceProfile = "xs"

      pods = {
        resources = {
          disableResourcesRequestsSplitFromTotal = true
          enableClusterLimitsRequirements        = false
        }

        persistentVolume = {
          size = "10Gi"
        }
      }

      distributedLogs = {
        sgDistributedLogs = kubernetes_manifest.sg_distributed_logs.manifest.metadata.name
      }

      configurations = {
        credentials = {
          users = {
            superuser = {
              username = {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "username"
              }
              password = {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "password"
              }
            }
          }
        }
      }

      prometheusAutobind = "false"

      # nonproductionoptions = {
      #   disableClusterPodAntiAffinity = true
      # }
    }
  }

  computed_fields = [
    "spec.postgres.version",
    "spec.initContainers",
  ]

  depends_on = [module.sg_instance_sizes]
}
