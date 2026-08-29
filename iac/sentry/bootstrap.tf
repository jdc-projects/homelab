# Post-deploy bootstrap (runs once after each deploy, idempotently):
#
#   1. Ensures the Sentry admin user exists with the password from
#      `random_password.sentry_admin_password` (stored in the sentry-secrets
#      Secret). The chart's `user.create` hook runs `createuser`, which creates
#      the superuser on first install but does NOT reset the password of an
#      already-existing user -- so across an interrupted reinstall (Postgres
#      persists) the DB password can drift from the secret. set_password keeps
#      them in sync. Re-runs on rotation (`replace_triggered_by`).
#
#   2. Pre-selects the OIDC auth provider on the org (sets the
#      `sentry:auth_provider` OrganizationOption to "oidc"). Sentry still
#      requires a one-time verification click (a deliberate lockout-safety
#      gate), but this removes the "pick provider" step from the UI flow.
#
# Both run in a single django shell exec against the running sentry-web pod,
# which already has the full chart config. No TF provider exists for Sentry
# users/org options, so this mirrors the clickhouse-provision pattern.
#
#   3. Mints an org-scoped Sentry auth token (ApiToken, USER type) for the
#      jianyuan/sentry Terraform provider and writes it to the sentry-auth-token
#      Secret. App modules consume it via the `sentry_auth_token` output (with a
#      "" default) so they can deploy before/without Sentry and self-serve their
#      own projects. Idempotent: if the Secret already exists, it is left alone
#      (the token plaintext is one-time-read, so it is captured on first mint).

resource "kubernetes_service_account" "sentry_bootstrap" {
  metadata {
    name      = "sentry-bootstrap"
    namespace = local.ns
  }
}

resource "kubernetes_role" "sentry_bootstrap" {
  metadata {
    name      = "sentry-bootstrap"
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

  # kubectl exec deployment/sentry-web resolves the Deployment to a pod.
  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["get"]
  }

  # Create/check the sentry-auth-token Secret (provider token minted below).
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create", "get"]
  }
}

resource "kubernetes_role_binding" "sentry_bootstrap" {
  metadata {
    name      = "sentry-bootstrap"
    namespace = local.ns
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.sentry_bootstrap.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.sentry_bootstrap.metadata[0].name
    namespace = local.ns
  }
}

resource "kubernetes_job" "sentry_bootstrap" {
  metadata {
    name      = "sentry-bootstrap"
    namespace = local.ns
  }

  spec {
    template {
      metadata {}

      spec {
        restart_policy       = "Never"
        service_account_name = kubernetes_service_account.sentry_bootstrap.metadata[0].name

        container {
          image = local.kubectl_image
          name  = "sentry-bootstrap"

          command = [
            "/bin/sh",
            "-c",
            <<-EOT
              kubectl -n ${local.ns} exec -i deployment/sentry-web -- sentry django shell <<'PY'
              from django.contrib.auth import get_user_model
              from sentry.models import Organization, OrganizationOption
              User = get_user_model()

              # 1. Admin user + password (matches sentry-secrets).
              u, created = User.objects.get_or_create(
                  email="${var.admin_email}",
                  defaults={"username": "${var.admin_email}"},
              )
              u.set_password("${random_password.sentry_admin_password.result}")
              u.is_superuser = True
              u.is_staff = True
              u.is_active = True
              u.save()
              print("admin user ready:", u.email, "| created:", created)

              # 2. Pre-select the OIDC provider on the org (single-org deploy).
              #    Verification is still a one-time manual click in the UI.
              org = Organization.objects.first()
              if org:
                  OrganizationOption.objects.set_value(org, "sentry:auth_provider", "oidc")
                  print("org", org.slug, "auth_provider -> oidc")
              else:
                  print("WARNING: no organization found; skipping auth_provider setup")
              PY

              # 3. Mint the jianyuan/sentry provider token (idempotent via Secret).
              if kubectl -n ${local.ns} get secret sentry-auth-token -o jsonpath='{.data.token}' 2>/dev/null | base64 -d 2>/dev/null | grep -q .; then
                echo "sentry-auth-token Secret already present"
              else
                kubectl -n ${local.ns} exec -i deployment/sentry-web -- sentry django shell <<'PY' > /tmp/token_raw.out
              from sentry.models import ApiToken
              from sentry.types.token import AuthTokenType
              from django.contrib.auth import get_user_model
              User = get_user_model()
              u = User.objects.get(email="${var.admin_email}")
              name = "terraform-provider"
              old = ApiToken.objects.filter(name=name, user_id=u.id).first()
              if old:
                  old.delete()
              t = ApiToken.objects.create(
                  user_id=u.id,
                  name=name,
                  token_type=AuthTokenType.USER,
                  scope_list=["org:read", "org:write", "org:admin", "team:read", "team:write", "project:read", "project:write", "project:admin", "project:releases"],
                  expires_at=None,
              )
              print("TOKEN_START")
              print(t.plaintext_token)
              print("TOKEN_END")
              PY
                TOKEN="$(sed -n '/TOKEN_START/{n;p;}' /tmp/token_raw.out | tr -d '[:space:]')"
                if [ -n "$TOKEN" ]; then
                  kubectl -n ${local.ns} create secret generic sentry-auth-token --from-literal=token="$TOKEN"
                  echo "minted provider token -> sentry-auth-token Secret"
                else
                  echo "ERROR: failed to mint provider token" >&2
                  exit 1
                fi
              fi
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

  # Re-run if the admin password is rotated.
  lifecycle {
    replace_triggered_by = [random_password.sentry_admin_password]
  }

  depends_on = [helm_release.sentry]
}

# Read the minted provider token back (the Secret is written by the job above)
# so it can be exported for app modules. depends_on defers the read until the
# bootstrap job has run on first apply (when the Secret is created).
data "kubernetes_secret" "sentry_auth_token" {
  metadata {
    name      = "sentry-auth-token"
    namespace = local.ns
  }

  depends_on = [kubernetes_job.sentry_bootstrap]
}
