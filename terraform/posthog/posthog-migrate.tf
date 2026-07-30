resource "kubernetes_job" "posthog_migrate" {
  metadata {
    name      = "posthog-migrate"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  spec {
    template {
      metadata {
        labels = { app = "posthog-migrate" }
      }

      spec {
        restart_policy = "Never"

        container {
          image   = local.posthog_image
          name    = "posthog-migrate"
          command = ["sh", "-c", "python manage.py migrate && python manage.py migrate_clickhouse && python manage.py run_async_migrations"]

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.posthog_secrets.metadata[0].name
            }
          }

          # Bypass PgBouncer for DDL — connect directly to Postgres.
          env {
            name  = "DATABASE_URL"
            value = local.database_url_direct
          }
          env {
            name  = "PGHOST"
            value = local.pg_host_direct
          }

          # On a fresh database, Django app startup queries posthog_asyncmigration
          # before `manage.py migrate` creates it. The explicit env overrides the
          # shared ConfigMap's normal value of 0 for initial bootstrap only.
          dynamic "env" {
            for_each = var.is_first_deploy ? [1] : []
            content {
              name  = "SKIP_ASYNC_MIGRATIONS_SETUP"
              value = "1"
            }
          }

          resources {
            requests = { cpu = "500m", memory = "1Gi" }
            limits   = { cpu = "1", memory = "2Gi" }
          }
        }
      }
    }

    backoff_limit              = 4
    ttl_seconds_after_finished = 86400
  }

  wait_for_completion = true

  lifecycle {
    replace_triggered_by = [kubernetes_job.clickhouse_provision]
  }

  timeouts {
    create = var.is_first_deploy ? "90m" : "15m"
    update = "15m"
  }

  depends_on = [
    kubernetes_manifest.posthog_db,
    kubernetes_manifest.posthog_clickhouse,
    kubernetes_job.clickhouse_provision,
    kubernetes_service.clickhouse,
    kubernetes_service.kafka,
    helm_release.valkey,
    kubernetes_job.rustfs_provision,
    kubernetes_job.rustfs_recordings_provision,
  ]
}
