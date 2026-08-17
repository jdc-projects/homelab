# Sentry

Self-hosted Sentry deployed via the [sentry-kubernetes/charts](https://github.com/sentry-kubernetes/charts)
Helm chart, running against in-cluster dependencies (CloudNative-PG, Valkey,
Strimzi Kafka, Altinity ClickHouse, RustFS) with **OIDC SSO** provided by the
[`sentry-auth-oidc`](https://github.com/siemens/sentry-auth-oidc) plugin baked
into a custom image ([jdc-projects/sentry-oidc](https://github.com/jdc-projects/sentry-oidc)).

The plugin is installed and its `OIDC_*` settings are injected into
`sentry.conf.py` (see `config.sentryConfPy` in `sentry.tf`). A Keycloak OIDC
client (`keycloak.tf`) and Traefik IngressRoutes for web + relay are provisioned
automatically.

## One-time post-deploy setup

Sentry's auth providers are **per-organization**: the OIDC provider is installed
and configured globally, and the post-deploy bootstrap Job (`bootstrap.tf`)
pre-selects it on the org. What remains manual is the one-time **verification**
click — Sentry requires it as a lockout-safety gate (prove SSO works before
relying on it), and it doubles as the end-to-end test of the Keycloak round-trip.

### 1. Retrieve the initial admin password

```bash
cd iac/sentry
tofu output -raw admin_password
# admin email:
tofu output -raw admin_email
```

> Equivalent cluster-side lookup (no tofu state needed):
> `kubectl -n sentry get secret sentry-secrets -o jsonpath='{.data.admin-password}' | base64 -d`

### 2. Log in and verify OIDC SSO

1. Open `https://sentry.<domain>/` and sign in with the admin email + password
   above. (The org slug is `sentry`, so the login URL is `/auth/login/sentry/`.)
2. Go to **Settings → Authentication**:
   `https://sentry.<domain>/settings/sentry/auth/`
3. **Keycloak** is already selected as the provider (the bootstrap Job sets
   `sentry:auth_provider=oidc`) — click **Configure**.
4. Sentry redirects to Keycloak — authenticate there and return. That
   verification step is what flips SSO to active.
5. Sign out. The login page now shows the **Keycloak** SSO button.

The OIDC redirect URI registered on the Keycloak client is
`https://sentry.<domain>/auth/sso/` (set in `keycloak.tf`).

### Post-deploy bootstrap (automated)

The `sentry-bootstrap` Job (`bootstrap.tf`) runs after each deploy and
idempotently:

- sets the admin user's password to match the `sentry-secrets` Secret (guards
  against the chart's `createuser` hook leaving it out of sync after an
  interrupted reinstall — `createuser` won't reset an existing user); re-runs
  automatically if the password is rotated (`replace_triggered_by`).
- pre-selects the OIDC provider on the org (`sentry:auth_provider=oidc`), so
  only the one-time verification click above is manual.

Last-resort manual reset (reads the password from the cluster Secret):

```bash
PASS=$(kubectl -n sentry get secret sentry-secrets -o jsonpath='{.data.admin-password}' | base64 -d)
kubectl -n sentry exec -i deploy/sentry-web -- sentry django shell <<EOF
from django.contrib.auth import get_user_model
User = get_user_model()
u = User.objects.get(email="$(tofu -chdir=iac/sentry output -raw admin_email)")
u.set_password("$PASS")
u.is_superuser = u.is_staff = u.is_active = True
u.save()
print("reset:", u.email)
EOF
```

## Notes

- **Backup scope** (velero): only the CNPG Postgres config DB (`sentry-db`, on
  `openebs-zfs-localpv-random`) is backed up — it holds orgs, projects, users,
  rules, tokens (all manual config). ClickHouse, Kafka, taskbroker and RustFS
  volumes use `openebs-zfs-localpv-bulk-no-backup` (skipped via the velero
  resource-policy): analytics data and release artifacts are treated as
  disposable in DR. After a restore, Postgres comes back populated and
  ClickHouse/Kafka come back empty (schema + topics re-provisioned by the
  operators/jobs).
- **Valkey is unauthenticated** (mirrors the PostHog module). The valkey.io chart
  uses ACL-based auth (`auth.aclUsers`), not a simple `auth.password`; wiring
  that is deferred to a hardening pass.
- **PgBouncer** runs in `session` mode so the chart's init hooks can run Django
  migrations through the same host the app uses.
- **ClickHouse** uses the AVX2-compat image (`clickhouse_compat_image`) and sets
  `allow_dimensions_outside_sorting_key=1` (Snuba's migrations require it).
