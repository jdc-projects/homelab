# Post-deploy bootstrap (runs after each coderd deploy, idempotently) —
# mirrors iac/sentry/bootstrap.tf.
#
# Coder's API only accepts tokens, and tokens can only be minted by an
# already-authenticated identity: tofu cannot own this credential end-to-end
# the way it owns keycloak/grafana admin secrets. The sentry-style workaround:
# mint it from INSIDE the deployment, where pod-exec is the auth.
#
#   1. Ensures a dedicated owner user `tofu-deploy` exists (with a password
#      from state, though password login is impossible here — see below) via
#      `coder server create-admin-user` exec'd in the coderd container, which
#      writes to the database directly using the pod's CODER_PG_CONNECTION_URL.
#
#   2. Inserts the API token row directly into Postgres on the CNPG primary.
#      Why not the API: coderd blocks POST /users/login outright while
#      CODER_DISABLE_PASSWORD_AUTH=true — even for owners (the "owner
#      exemption" in coderd/userauth.go is a comment, not code, as of v2.36.7
#      and current main) — so there is no API path from pod-exec to a first
#      token. The INSERT replicates what coderd's own apikey.Generate +
#      InsertAPIKey do (verified against v2.36.7 source):
#        token = <10-char id>-<22-char secret>
#        hashed_secret = raw sha256(secret)  (bytea, not hex)
#        scopes = ['all'], allow_list = ['*:*'], login_type = 'token'
#
#   3. Writes the token to the coder-api-token Secret. The iac/coder-template
#      module consumes it via the coder_api_token output.
#
# Idempotent: if the Secret already exists it is left alone (token plaintext
# is shown once), so re-runs never mint duplicates.

locals {
  kubectl_image = "alpine/kubectl:1.33.4"
}

resource "random_password" "coder_bootstrap_password" {
  length  = 32
  special = false
}

resource "kubernetes_service_account" "coder_bootstrap" {
  metadata {
    name      = "coder-bootstrap"
    namespace = kubernetes_namespace.coder.metadata[0].name
  }
}

resource "kubernetes_role" "coder_bootstrap" {
  metadata {
    name      = "coder-bootstrap"
    namespace = kubernetes_namespace.coder.metadata[0].name
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

  # kubectl exec deploy/coder resolves the Deployment to a pod.
  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["get"]
  }

  # Create/check the coder-api-token Secret (token minted below).
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create", "get"]
  }
}

resource "kubernetes_role_binding" "coder_bootstrap" {
  metadata {
    name      = "coder-bootstrap"
    namespace = kubernetes_namespace.coder.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.coder_bootstrap.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.coder_bootstrap.metadata[0].name
    namespace = kubernetes_namespace.coder.metadata[0].name
  }
}

resource "kubernetes_job" "coder_bootstrap" {
  metadata {
    name      = "coder-bootstrap"
    namespace = kubernetes_namespace.coder.metadata[0].name
  }

  spec {
    template {
      metadata {}

      spec {
        restart_policy       = "Never"
        service_account_name = kubernetes_service_account.coder_bootstrap.metadata[0].name

        container {
          image = local.kubectl_image
          name  = "coder-bootstrap"

          command = [
            "/bin/sh",
            "-c",
            <<-EOT
              set -eu

              # Gate: never touch an existing token.
              if kubectl -n ${kubernetes_namespace.coder.metadata[0].name} get secret coder-api-token -o jsonpath='{.data.token}' 2>/dev/null | base64 -d 2>/dev/null | grep -q .; then
                echo "coder-api-token Secret already present"
                exit 0
              fi

              apk add --no-cache openssl >/dev/null

              # 1. Ensure the automation owner exists (plain DB INSERT via the
              #    coderd container; tolerates already-exists on reruns).
              kubectl -n ${kubernetes_namespace.coder.metadata[0].name} exec deploy/${helm_release.coder.name} -- \
                /opt/coder server create-admin-user \
                --username tofu-deploy --email tofu-deploy@jd-chapman.dev \
                --password '${random_password.coder_bootstrap_password.result}' || true

              # 2. Mint the token row on the CNPG primary (see header).
              ID="$$(openssl rand -hex 5)"       # 10 chars — httpmw.SplitAPIToken requires exactly this
              SECRET="$$(openssl rand -hex 11)"  # 22 chars — ditto
              HASH="$$(printf %s "$$SECRET" | sha256sum | awk '{print $$1}')"
              NAME="tofu-deploy-$$(date +%s)"    # unique, survives partial-failure reruns

              DB_POD="$$(kubectl -n ${kubernetes_namespace.coder.metadata[0].name} get pods \
                -l cnpg.io/instanceRole=primary -o jsonpath='{.items[0].metadata.name}')"
              [ -n "$$DB_POD" ] || { echo "ERROR: CNPG primary pod not found" >&2; exit 1; }

              USER_ID="$$(kubectl -n ${kubernetes_namespace.coder.metadata[0].name} exec "$$DB_POD" -- \
                psql -d coder -tAc "SELECT id FROM users WHERE username = 'tofu-deploy'" | tr -d '[:space:]')"
              [ -n "$$USER_ID" ] || { echo "ERROR: tofu-deploy user not found" >&2; exit 1; }

              kubectl -n ${kubernetes_namespace.coder.metadata[0].name} exec "$$DB_POD" -- \
                psql -d coder -v ON_ERROR_STOP=1 -c "
              INSERT INTO api_keys (
                id, hashed_secret, user_id, last_used, expires_at,
                created_at, updated_at, login_type, lifetime_seconds,
                ip_address, token_name, scopes, allow_list
              ) VALUES (
                '$$ID',
                decode('$$HASH', 'hex'),
                '$$USER_ID'::uuid,
                '1970-01-01T00:00:00Z',
                to_timestamp($$(date +%s) + 157680000),
                now(), now(),
                'token',
                157680000,
                '0.0.0.0',
                '$$NAME',
                ARRAY['coder:all']::api_key_scope[],
                ARRAY['*:*']::text[]
              )"

              # 3. Publish. Token plaintext = <id>-<secret>; never logged.
              kubectl -n ${kubernetes_namespace.coder.metadata[0].name} create secret generic coder-api-token \
                --from-literal=token="$$ID-$$SECRET"
              echo "minted coderd API token -> coder-api-token Secret"
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
    create = "6m"
    update = "6m"
  }

  # Re-run if the automation user's password is rotated.
  lifecycle {
    replace_triggered_by = [random_password.coder_bootstrap_password]
  }

  depends_on = [helm_release.coder]
}

# Read the minted token back (the Secret is written by the job above) so it
# can be exported for iac/coder-template's coderd provider — the
# sentry_auth_token pattern. depends_on defers the read until the bootstrap
# job has run on first apply (when the Secret is created).
data "kubernetes_secret" "coder_api_token" {
  metadata {
    name      = "coder-api-token"
    namespace = kubernetes_namespace.coder.metadata[0].name
  }

  depends_on = [kubernetes_job.coder_bootstrap]
}
