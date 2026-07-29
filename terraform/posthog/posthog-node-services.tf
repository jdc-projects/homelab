# ==================== Node services ====================

resource "kubernetes_deployment" "plugins" {
  metadata {
    name      = "plugins"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  spec {
    replicas = 1
    selector {
      match_labels = { app = "plugins" }
    }
    template {
      metadata {
        labels = { app = "plugins" }
      }
      spec {
        container {
          image   = local.posthog_node_img
          name    = "plugins"
          command = ["node", "nodejs/dist/index.js"]

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.posthog_secrets.metadata[0].name }
          }

          port { container_port = 6738 }

          resources {
            requests = { cpu = "200m", memory = "512Mi" }
            limits   = { cpu = "500m", memory = "1Gi" }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_job.posthog_migrate]
}

resource "kubernetes_service" "plugins" {
  metadata {
    name      = "plugins"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    selector = { app = "plugins" }
    port {
      port        = 6738
      target_port = 6738
    }
  }
}

resource "kubernetes_deployment" "ingestion_general" {
  metadata {
    name      = "ingestion-general"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "ingestion-general" }
    }
    template {
      metadata {
        labels = { app = "ingestion-general" }
      }
      spec {
        container {
          image   = local.posthog_node_img
          name    = "ingestion-general"
          command = ["node", "nodejs/dist/index.js"]

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }
          env_from {
            config_map_ref { name = kubernetes_config_map.node_service_config["ingestion-general"].metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.posthog_secrets.metadata[0].name }
          }

          resources {
            requests = { cpu = "200m", memory = "512Mi" }
            limits   = { cpu = "500m", memory = "1Gi" }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_job.posthog_migrate]
}

resource "kubernetes_deployment" "ingestion_sessionreplay" {
  metadata {
    name      = "ingestion-sessionreplay"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "ingestion-sessionreplay" }
    }
    template {
      metadata {
        labels = { app = "ingestion-sessionreplay" }
      }
      spec {
        container {
          image   = local.posthog_node_img
          name    = "ingestion-sessionreplay"
          command = ["node", "nodejs/dist/index.js"]

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }
          env_from {
            config_map_ref { name = kubernetes_config_map.node_service_config["ingestion-sessionreplay"].metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.posthog_secrets.metadata[0].name }
          }

          resources {
            requests = { cpu = "200m", memory = "512Mi" }
            limits   = { cpu = "500m", memory = "1Gi" }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_job.posthog_migrate]
}

resource "kubernetes_deployment" "recording_api" {
  metadata {
    name      = "recording-api"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "recording-api" }
    }
    template {
      metadata {
        labels = { app = "recording-api" }
      }
      spec {
        container {
          image   = local.posthog_node_img
          name    = "recording-api"
          command = ["node", "nodejs/dist/index.js"]

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }
          env_from {
            config_map_ref { name = kubernetes_config_map.node_service_config["recording-api"].metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.posthog_secrets.metadata[0].name }
          }

          port { container_port = 6738 }

          resources {
            requests = { cpu = "200m", memory = "512Mi" }
            limits   = { cpu = "500m", memory = "1Gi" }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_job.posthog_migrate]
}

resource "kubernetes_service" "recording_api" {
  metadata {
    name      = "recording-api"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    selector = { app = "recording-api" }
    port {
      port        = 6738
      target_port = 6738
    }
  }
}

resource "kubernetes_deployment" "ingestion_error_tracking" {
  metadata {
    name      = "ingestion-error-tracking"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "ingestion-error-tracking" }
    }
    template {
      metadata {
        labels = { app = "ingestion-error-tracking" }
      }
      spec {
        container {
          image   = local.posthog_node_img
          name    = "ingestion-error-tracking"
          command = ["node", "nodejs/dist/index.js"]

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }
          env_from {
            config_map_ref { name = kubernetes_config_map.node_service_config["ingestion-error-tracking"].metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.posthog_secrets.metadata[0].name }
          }

          resources {
            requests = { cpu = "200m", memory = "512Mi" }
            limits   = { cpu = "500m", memory = "1Gi" }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_job.posthog_migrate]
}

resource "kubernetes_deployment" "ingestion_logs" {
  metadata {
    name      = "ingestion-logs"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "ingestion-logs" }
    }
    template {
      metadata {
        labels = { app = "ingestion-logs" }
      }
      spec {
        container {
          image   = local.posthog_node_img
          name    = "ingestion-logs"
          command = ["node", "nodejs/dist/index.js"]

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }
          env_from {
            config_map_ref { name = kubernetes_config_map.node_service_config["ingestion-logs"].metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.posthog_secrets.metadata[0].name }
          }

          resources {
            requests = { cpu = "200m", memory = "512Mi" }
            limits   = { cpu = "500m", memory = "1Gi" }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_job.posthog_migrate]
}

resource "kubernetes_deployment" "ingestion_traces" {
  metadata {
    name      = "ingestion-traces"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "ingestion-traces" }
    }
    template {
      metadata {
        labels = { app = "ingestion-traces" }
      }
      spec {
        container {
          image   = local.posthog_node_img
          name    = "ingestion-traces"
          command = ["node", "nodejs/dist/index.js"]

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }
          env_from {
            config_map_ref { name = kubernetes_config_map.node_service_config["ingestion-traces"].metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.posthog_secrets.metadata[0].name }
          }

          resources {
            requests = { cpu = "200m", memory = "512Mi" }
            limits   = { cpu = "500m", memory = "1Gi" }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_job.posthog_migrate]
}
