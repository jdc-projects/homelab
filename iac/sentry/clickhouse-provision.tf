resource "kubernetes_service_account" "clickhouse_provision" {
  metadata {
    name      = "clickhouse-provision"
    namespace = local.ns
  }
}

resource "kubernetes_role" "clickhouse_provision" {
  metadata {
    name      = "clickhouse-provision"
    namespace = local.ns
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
    namespace = local.ns
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.clickhouse_provision.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.clickhouse_provision.metadata[0].name
    namespace = local.ns
  }
}

# Create Sentry's ClickHouse database + user from inside the pod. The Altinity
# operator restricts the default user's networks and does not materialise custom
# users from the CHI users map, so this runs via SQL access management. Snuba's
# init/migrate hooks (run by the chart) then create their datasets in the
# "sentry" database.
resource "kubernetes_job" "clickhouse_provision" {
  metadata {
    name      = "clickhouse-provision"
    namespace = local.ns
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
              namespace="${local.ns}"
              selector="clickhouse.altinity.com/chi=sentry-ch"

              until pod="$$(kubectl -n "$$namespace" get pods -l "$$selector" -o jsonpath='{.items[0].metadata.name}')" && [ -n "$$pod" ]; do
                echo "waiting for ClickHouse pod..."
                sleep 2
              done

              kubectl -n "$$namespace" wait --for=condition=Ready "pod/$$pod" --timeout=5m
              kubectl -n "$$namespace" exec "$$pod" -- \
                clickhouse-client --user default --password "" --query \
                "CREATE USER IF NOT EXISTS sentry IDENTIFIED WITH no_password"
              kubectl -n "$$namespace" exec "$$pod" -- \
                clickhouse-client --user default --password "" --query \
                "CREATE DATABASE IF NOT EXISTS sentry"
              kubectl -n "$$namespace" exec "$$pod" -- \
                clickhouse-client --user default --password "" --query \
                "GRANT CURRENT GRANTS ON *.* TO sentry"
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

  depends_on = [kubernetes_manifest.sentry_clickhouse]
}
