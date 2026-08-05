resource "kubernetes_service_account" "clickhouse_provision" {
  metadata {
    name      = "clickhouse-provision"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
}

resource "kubernetes_role" "clickhouse_provision" {
  metadata {
    name      = "clickhouse-provision"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/exec"]
    verbs      = ["create"]
  }
}

resource "kubernetes_role_binding" "clickhouse_provision" {
  metadata {
    name      = "clickhouse-provision"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.clickhouse_provision.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.clickhouse_provision.metadata[0].name
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
}

# The Altinity operator restricts the default user's networks and does not
# materialise custom users from the CHI users map. Create PostHog's application
# user through SQL access management from inside the ClickHouse pod.
resource "kubernetes_job" "clickhouse_provision" {
  metadata {
    name      = "clickhouse-provision"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  spec {
    template {
      metadata {}

      spec {
        restart_policy       = "OnFailure"
        service_account_name = kubernetes_service_account.clickhouse_provision.metadata[0].name

        container {
          image = local.kubectl_image
          name  = "clickhouse-provision"

          command = [
            "/bin/sh",
            "-c",
            <<-EOT
              set -eu
              namespace="${kubernetes_namespace.posthog.metadata[0].name}"
              selector="clickhouse.altinity.com/chi=posthog-ch"

              until pod="$$(kubectl -n "$$namespace" get pods -l "$$selector" -o jsonpath='{.items[0].metadata.name}')" && [ -n "$$pod" ]; do
                echo "waiting for ClickHouse pod..."
                sleep 2
              done

              kubectl -n "$$namespace" wait --for=condition=Ready "pod/$$pod" --timeout=5m
              kubectl -n "$$namespace" exec "$$pod" -- \
                clickhouse-client --user default --password "" --query \
                "CREATE USER IF NOT EXISTS posthog IDENTIFIED WITH no_password"
              kubectl -n "$$namespace" exec "$$pod" -- \
                clickhouse-client --user default --password "" --query \
                "GRANT CURRENT GRANTS ON *.* TO posthog"

              # Force flush of all system log buffers. ClickHouse 26.8 uses lazy
              # table creation for system logs — tables like crash_log and
              # backup_log only materialise when first data is written. Without
              # this, migrate_clickhouse fails because the tables don't exist yet.
              kubectl -n "$$namespace" exec "$$pod" -- \
                clickhouse-client --user default --password "" --query \
                "SYSTEM FLUSH LOGS"
            EOT
          ]
        }
      }
    }

    backoff_limit              = 4
    ttl_seconds_after_finished = 86400
  }

  wait_for_completion = true

  timeouts {
    create = "10m"
    update = "10m"
  }

  depends_on = [kubernetes_manifest.posthog_clickhouse]
}
