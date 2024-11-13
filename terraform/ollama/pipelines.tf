resource "kubernetes_secret" "pipelines_env" {
  metadata {
    name      = "pipelines-env"
    namespace = kubernetes_namespace.ollama.metadata[0].name
  }

  data = {
    PIPELINES_API_KEY = random_password.pipelines_api_key.result
  }
}

resource "kubernetes_deployment" "pipelines" {
  metadata {
    name      = "pipelines"
    namespace = kubernetes_namespace.ollama.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "pipelines"
      }
    }

    template {
      metadata {
        labels = {
          app = "pipelines"
        }
      }

      spec {
        container {
          image = "ghcr.io/open-webui/pipelines:git-c98ca76" # pipelines currently doesn't do releases / versions
          name  = "pipelines"

          env_from {
            secret_ref {
              name = kubernetes_secret.pipelines_env.metadata[0].name
            }
          }

          volume_mount {
            mount_path = "/app/backend/data"
            name       = "pipelines-data"
          }

          resources {
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }

            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }

        volume {
          name = "pipelines-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.ollama["pipelines"].metadata[0].name
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_secret.pipelines_env,
    ]
  }
}
