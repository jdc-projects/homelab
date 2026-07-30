resource "kubernetes_deployment" "posthog_web" {
  metadata {
    name      = "web"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = { app = "web" }
    }

    template {
      metadata {
        labels = { app = "web" }
      }

      spec {
        container {
          image   = local.posthog_image
          name    = "web"
          command = ["sh", "-c", "./bin/start-backend"]

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }
          env_from {
            config_map_ref { name = kubernetes_config_map.web_config.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.posthog_secrets.metadata[0].name }
          }

          port { container_port = 8000 }

          resources {
            requests = { cpu = "1", memory = "2Gi" }
            limits   = { cpu = "2", memory = "4Gi" }
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.posthog_env,
      kubernetes_config_map.web_config,
      kubernetes_secret.posthog_secrets,
    ]
  }

  depends_on = [
    kubernetes_manifest.posthog_db,
    kubernetes_manifest.posthog_db_pooler,
    kubernetes_manifest.posthog_clickhouse,
    kubernetes_job.rustfs_provision,
    kubernetes_job.rustfs_recordings_provision,
    module.temporal,
    kubernetes_deployment.feature_flags,
    kubernetes_deployment.personhog_router,
    kubernetes_deployment.browserless,
    kubernetes_job.posthog_migrate,
  ]
}

resource "kubernetes_service" "posthog_web" {
  metadata {
    name      = "web"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  spec {
    selector = { app = "web" }
    port {
      port        = 8000
      target_port = 8000
    }
  }
}
