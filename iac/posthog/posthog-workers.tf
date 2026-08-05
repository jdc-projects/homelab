resource "kubernetes_deployment" "posthog_worker" {
  metadata {
    name      = "worker"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "worker" }
    }

    template {
      metadata {
        labels = { app = "worker" }
        annotations = {
          "checksum/posthog-env"     = sha1(jsonencode(kubernetes_config_map.posthog_env.data))
          "checksum/posthog-secrets" = sha1(jsonencode(kubernetes_secret.posthog_secrets.data))
        }
      }

      spec {
        container {
          image   = local.posthog_image
          name    = "worker"
          command = ["sh", "-c", "./bin/docker-worker-celery --with-scheduler"]

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }

          env_from {
            secret_ref { name = kubernetes_secret.posthog_secrets.metadata[0].name }
          }

          resources {
            requests = { cpu = "250m", memory = "1Gi" }
            limits   = { cpu = "1", memory = "8Gi" }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_manifest.posthog_db,
    kubernetes_manifest.posthog_db_pooler,
    kubernetes_manifest.posthog_clickhouse,
    kubernetes_job.posthog_migrate,
  ]
}

resource "kubernetes_deployment" "temporal_django_worker" {
  metadata {
    name      = "temporal-django-worker"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "temporal-django-worker" }
    }

    template {
      metadata {
        labels = { app = "temporal-django-worker" }
        annotations = {
          "checksum/posthog-env"     = sha1(jsonencode(kubernetes_config_map.posthog_env.data))
          "checksum/posthog-secrets" = sha1(jsonencode(kubernetes_secret.posthog_secrets.data))
        }
      }

      spec {
        container {
          image   = local.posthog_image
          name    = "temporal-django-worker"
          command = ["sh", "-c", "./bin/temporal-django-worker"]

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }

          env_from {
            secret_ref { name = kubernetes_secret.posthog_secrets.metadata[0].name }
          }

          resources {
            requests = { cpu = "250m", memory = "512Mi" }
            limits   = { cpu = "500m", memory = "1Gi" }
          }
        }
      }
    }
  }

  depends_on = [
    module.temporal,
    kubernetes_manifest.posthog_db_pooler,
    kubernetes_job.posthog_migrate,
  ]
}
