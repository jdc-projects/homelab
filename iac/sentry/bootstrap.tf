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
