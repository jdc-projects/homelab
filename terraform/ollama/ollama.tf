resource "kubernetes_config_map" "ollama_env" {
  metadata {
    name      = "ollama-env"
    namespace = kubernetes_namespace.ollama.metadata[0].name
  }

  data = {
    OLLAMA_DEBUG = "false"
  }
}

resource "kubernetes_deployment" "ollama" {
  metadata {
    name      = "ollama"
    namespace = kubernetes_namespace.ollama.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "ollama"
      }
    }

    template {
      metadata {
        labels = {
          app = "ollama"
        }
      }

      spec {
        container {
          image = "ollama/ollama:0.4.1"
          name  = "ollama"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.ollama_env.metadata[0].name
            }
          }

          volume_mount {
            mount_path = "/root/.ollama/models"
            name       = "ollama-data"
          }

          resources {
            requests = {
              cpu    = "5"
              memory = "32Gi"
            }

            limits = {
              cpu    = "20"
              memory = "128Gi"
            }
          }
        }

        volume {
          name = "ollama-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.ollama["ollama"].metadata[0].name
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.ollama_env,
    ]
  }
}
