resource "kubernetes_deployment" "prowler_worker_beat" {
  metadata {
    name      = "prowler-worker-beat"
    namespace = kubernetes_namespace.prowler.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "prowler-worker-beat"
      }
    }

    template {
      metadata {
        labels = {
          app = "prowler-worker-beat"
        }
      }

      spec {
        container {
          image = "prowlercloud/prowler-api:${local.prowler_version}"
          name  = "prowler-api"

          command = [
            "/home/prowler/docker-entrypoint.sh",
            "beat",
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

          resources {
            requests = {
              cpu    = "200m"
              memory = "512Mi"
            }

            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
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
