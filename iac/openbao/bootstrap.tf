# One-time OpenBao initialization, fully in-cluster (mirrors the sentry
# bootstrap pattern: kubernetes_job + dedicated SA, idempotent, re-created on
# chart changes where it just no-ops).
#
#   1. Waits for the OpenBao API (the chart service publishes not-ready
#      endpoints, and `bao status` answers while sealed).
#   2. If uninitialized: `bao operator init -key-shares=1 -key-threshold=1`
#      and stores the results as two Secrets in this namespace:
#        openbao-seal      (unseal-key)  -> read by the unseal sidecar
#        openbao-bootstrap (root-token)  -> read once for iac/openbao-config
#   3. Waits for the sidecar to unseal.
#
# The unseal key / root token never pass through tofu state or the runner.

resource "kubernetes_service_account" "openbao_bootstrap" {
  metadata {
    name      = "openbao-bootstrap"
    namespace = kubernetes_namespace.openbao.metadata[0].name
  }
}

resource "kubernetes_role" "openbao_bootstrap" {
  metadata {
    name      = "openbao-bootstrap"
    namespace = kubernetes_namespace.openbao.metadata[0].name
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

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create", "get"]
  }
}

resource "kubernetes_role_binding" "openbao_bootstrap" {
  metadata {
    name      = "openbao-bootstrap"
    namespace = kubernetes_namespace.openbao.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.openbao_bootstrap.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.openbao_bootstrap.metadata[0].name
    namespace = kubernetes_namespace.openbao.metadata[0].name
  }
}

resource "kubernetes_job" "openbao_bootstrap" {
  metadata {
    name      = "openbao-bootstrap"
    namespace = kubernetes_namespace.openbao.metadata[0].name
  }

  spec {
    template {
      metadata {}

      spec {
        restart_policy       = "Never"
        service_account_name = kubernetes_service_account.openbao_bootstrap.metadata[0].name

        container {
          image = local.kubectl_image
          name  = "openbao-bootstrap"

          command = [
            "/bin/sh",
            "-ec",
            <<-EOT
              NS=${kubernetes_namespace.openbao.metadata[0].name}
              POD=openbao-0

              # 1. Wait for the OpenBao API to answer (sealed is fine — note
              #    `bao status` exits 2 while sealed, so test for output, not
              #    exit code).
              i=0
              until kubectl -n "$NS" exec "$POD" -c openbao -- bao status -format=json 2>/dev/null | grep -q '"storage_type"'; do
                i=$((i+1))
                if [ "$i" -ge 60 ]; then
                  echo "ERROR: OpenBao API not reachable after 5m" >&2
                  exit 1
                fi
                sleep 5
              done

              # 2. Initialize exactly once.
              STATUS="$(kubectl -n "$NS" exec "$POD" -c openbao -- bao status -format=json | tr -d '\n')"
              if echo "$STATUS" | grep -q '"initialized": *false'; then
                if kubectl -n "$NS" get secret openbao-seal >/dev/null 2>&1; then
                  echo "ERROR: OpenBao is uninitialized but the openbao-seal Secret exists;" >&2
                  echo "       refusing to re-init over possibly-data-bearing storage." >&2
                  exit 1
                fi

                echo "initializing OpenBao..."
                OUT="$(kubectl -n "$NS" exec "$POD" -c openbao -- bao operator init -key-shares=1 -key-threshold=1 -format=json | tr -d ' \n\t\r')"
                KEY="$(echo "$OUT" | sed -n 's/.*"unseal_keys_b64":\["\([^"]*\)".*/\1/p')"
                if [ -z "$KEY" ]; then
                  KEY="$(echo "$OUT" | sed -n 's/.*"keys_base64":\["\([^"]*\)".*/\1/p')"
                fi
                TOKEN="$(echo "$OUT" | sed -n 's/.*"root_token":"\([^"]*\)".*/\1/p')"

                if [ -z "$KEY" ] || [ -z "$TOKEN" ]; then
                  # Safety net: init output is one-time; preserve it for manual
                  # recovery rather than losing the instance.
                  kubectl -n "$NS" create secret generic openbao-init-raw --from-literal=init-output="$OUT" >/dev/null 2>&1 || true
                  echo "ERROR: failed to parse operator init output (raw output stored in the openbao-init-raw Secret)" >&2
                  exit 1
                fi

                kubectl -n "$NS" create secret generic openbao-seal --from-literal=unseal-key="$KEY"
                kubectl -n "$NS" create secret generic openbao-bootstrap --from-literal=root-token="$TOKEN"
                echo "initialized; openbao-seal + openbao-bootstrap Secrets created"
              else
                echo "already initialized; nothing to do"
              fi

              # 3. Wait for the unseal sidecar to unseal (exit code 0).
              i=0
              until kubectl -n "$NS" exec "$POD" -c openbao -- bao status >/dev/null 2>&1; do
                i=$((i+1))
                if [ "$i" -ge 60 ]; then
                  echo "ERROR: OpenBao still sealed after 5m (unseal sidecar should have picked it up)" >&2
                  exit 1
                fi
                sleep 5
              done
              echo "OpenBao is initialized and unsealed"
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
    create = "15m"
    update = "15m"
  }

  # Re-run (idempotently) whenever the chart changes.
  lifecycle {
    replace_triggered_by = [helm_release.openbao]
  }

  depends_on = [
    helm_release.openbao,
    kubernetes_manifest.openbao_db,
  ]
}
