resource "kubernetes_deployment" "prowler_worker" {
  metadata {
    name      = "prowler-worker"
    namespace = kubernetes_namespace.prowler.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "prowler-worker"
      }
    }

    template {
      metadata {
        labels = {
          app = "prowler-worker"
        }
      }

      spec {
        container {
          image = "prowlercloud/prowler-api:${local.prowler_version}"
          name  = "prowler-worker"

          command = [
            "/home/prowler/docker-entrypoint.sh",
            "worker",
          ]

          env_from {
            config_map_ref {
              name = kubernetes_config_map.prowler_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.prowler_env.metadata[0].name
            }
          }

          volume_mount {
            mount_path = kubernetes_config_map.prowler_env.data.DJANGO_TMP_OUTPUT_DIRECTORY
            name       = "prowler-api-output"
          }

          resources {
            requests = {
              cpu    = "200m"
              memory = "2Gi"
            }

            limits = {
              cpu    = "500m"
              memory = "4Gi"
            }
          }
        }

        volume {
          name = "prowler-api-output"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.prowler_api_output.metadata[0].name
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.prowler_env,
      kubernetes_secret.prowler_env
    ]
  }
}
