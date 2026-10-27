# Coder

[Coder](https://coder.com) — remote development environments. Deploys the OSS
(non-enterprise) control plane via the official Helm chart (`oci://ghcr.io/coder/chart/coder`,
pinned `2.36.7`, current **stable** channel). No `CODER_LICENSE` is set, so only
AGPL features are active: single `coderd` replica, no workspace proxies, no
external provisioner daemons, no SCIM, and the embedded AI Gateway is
explicitly disabled (`CODER_AI_GATEWAY_ENABLED=false` — it is Premium-licensed,
so OSS deployments cannot use it).

| Piece        | What                                                                |
| ------------ | ------------------------------------------------------------------- |
| `coderd`     | Helm release `coder`, ~250m/512Mi requests, ClusterIP Service :80   |
| Database     | CNPG `Cluster` `coder-db` (2 instances, 10Gi `openebs-zfs-localpv-random`, PodMonitor on) |
| Auth         | Keycloak OIDC (`keycloak.tf`), password auth disabled                |
| Ingress      | apex `coder.jd-chapman.dev` + suffix wildcard route (below)          |
| Metrics      | `ServiceMonitor` scraping coderd `:2112` via Service `coder-metrics` |
| Dashboards   | `dashboards/coder.json` → GrafanaDashboard CR                       |
| Workspaces   | tofu-managed template `default` (../coder-template), pods in `coder-workspaces` ns |

## Workspace-app wildcard: suffix form (`*-coder.jd-chapman.dev`)

Coder serves workspace apps (code-server, dashboard port-forwards) on generated
hostnames. `CODER_WILDCARD_ACCESS_URL` uses the **suffix** form, so app
hostnames look like `8080--main--myworkspace--jack-coder.jd-chapman.dev` — a
single DNS label under the zone.

Why not `*.coder.jd-chapman.dev`: those are second-level subdomains, which
(verified) neither Cloudflare's edge certificate (Universal SSL covers only the
apex + first-level wildcard — [limitations](https://developers.cloudflare.com/ssl/edge-certificates/universal-ssl/limitations/))
nor the cluster's default `*.jd-chapman.dev` origin cert would cover. The suffix
form rides the existing proxied wildcard DNS record and default TLS cert with
zero Cloudflare changes. Cloudflare's authoritative DNS *does* synthesise
answers for arbitrary-depth names in proxied zones, but the edge then refuses
the TLS handshake for them — do not rely on that behaviour.

Consequences / mitigations:

- The Traefik route is a hand-rolled `HostRegexp(`^[a-zA-Z0-9-]+-coder\.…$`)`
  IngressRoute with the standard shared middleware chain (cloudflare, geoblock,
  crowdsec-bouncer). `modules/ingress` only emits exact `Host()` matches.
- **`-coder` is a reserved hostname suffix** on the zone; a future app whose
  label ends in `-coder` would be captured by this route.
- App-session cookies would normally be scoped to `.jd-chapman.dev` (parent of
  the wildcard pattern), i.e. sent to every sibling app. `CODER_HOST_PREFIX_COOKIE=true`
  makes coderd use host-only `__Host-` cookies instead (fresh deployment, so the
  documented 2.31 migration caveat does not apply).
- Path-based workspace apps are disabled (`CODER_DISABLE_PATH_APPS=true`) per
  Coder's security recommendation once a wildcard is configured.

## Auth

- Keycloak confidential client `coder`; redirect URI
  `https://coder.jd-chapman.dev/api/v2/users/oidc/callback` (note: differs from
  the `/oidc/callback` convention other apps use).
- `CODER_OIDC_IGNORE_EMAIL_VERIFIED=true` — Keycloak/LDAP-federated emails are
  frequently unverified.
- Password auth is disabled. **Bootstrap quirk (2.36): the `/setup` first-user
  page only renders GitHub + password — no OIDC option — and `/login` is only
  reachable once a user exists.** The default GitHub *login* provider is
  disabled via commandArgs, so `/setup` shows just the password form. Two ways
  to create the owner:
  1. Passwordless: open `https://coder.jd-chapman.dev/api/v2/users/oidc/callback?redirect=/`
     directly and sign in with Keycloak (the login button's own href; the
     first user becomes owner).
  2. Designed path: create the owner on `/setup` using the **same email as the
     Keycloak account** (any password), sign out, then use "Sign in with
     Keycloak" on `/login` — OIDC matches the existing account by email.
- **Password login is fully blocked** while `CODER_DISABLE_PASSWORD_AUTH=true`
  — including for owners: the "owner exemption" in `coderd/userauth.go` is a
  comment, not code (verified v2.36.7 and current main; the API returns
  `403 Password authentication is disabled.` even with correct owner
  credentials). Lockout recovery: temporarily remove that env var, or mint an
  `api_keys` row via psql — `bootstrap.tf` demonstrates the latter.

## Known quirk: GitHub external-auth env var

`CODER_EXTERNAL_AUTH_GITHUB_DEFAULT_PROVIDER_ENABLE` (and the deprecated
`CODER_OAUTH2_…` alias, which is silently ignored) crashes coderd 2.36.7 with
`read external auth providers from env: parse number: …`. The flag is passed as
a CLI arg via `coder.commandArgs` instead. Re-test on upgrade.

## Observability

| Signal   | Status | Notes                                                                                                        |
| -------- | ------ | ------------------------------------------------------------------------------------------------------------ |
| Tracing  | ✅     | Native OTel (`CODER_TRACE_ENABLE` + OTLP http/protobuf → `otel-collector.otel.svc:4318`). No `Instrumentation` CR — coderd is Go with a native SDK; injection is unnecessary. |
| Metrics  | ✅     | `CODER_PROMETHEUS_ENABLE=true` on `:2112`; chart Service doesn't expose it, so Service `coder-metrics` + `ServiceMonitor` do. Verified: 292 coderd series. |
| Errors   | ❌     | coderd does not bundle the Sentry SDK (`go.mod` @ v2.36.5 has no sentry dependency) — nothing to wire.       |
| Logs     | ✅     | Plain stdout → kubectl/Loki as usual.                                                                        |

## Workspaces

- Workspaces (Deployment + home PVC) land in the **`coder-workspaces`**
  namespace, isolated from the coderd control plane and its database; RBAC is
  granted by the chart's `coder.serviceAccount.workspaceNamespaces` value.
- The default template (`default`, displayed "Default (Kubernetes)") is
  **tofu-managed** by the sibling
  **`iac/coder-template`** module — separate because its `coder/coderd`
  provider needs a running coderd even at plan time (state refresh), and this
  module must stay plannable while coderd is down (first bootstrap, DB
  hibernation). Template lifecycle, auth and versioning are documented there.

## Automation auth (bootstrap.tf)

Coder's API only accepts tokens, and tokens can only be minted by an
already-authenticated identity — tofu can't own this credential end-to-end
like the keycloak/grafana admin secrets. `bootstrap.tf` (sentry-style) solves
it from inside the deployment, as an idempotent post-deploy Job:

1. `coder server create-admin-user` exec'd in the coderd container creates a
   dedicated owner `tofu-deploy` (plain DB INSERT via the pod's
   `CODER_PG_CONNECTION_URL`; exec'ing our own pod is the auth).
2. The token row is INSERTed directly into `api_keys` on the CNPG primary,
   replicating coderd's own `apikey.Generate` (verified against v2.36.7
   source): `token = <10-char id>-<22-char secret>`, `hashed_secret` = raw
   sha256(secret), `scopes = ['coder:all']`, 5y expiry. There is no API path
   for this: coderd blocks `POST /users/login` outright while
   `CODER_DISABLE_PASSWORD_AUTH=true` — even for owners (the "owner exemption"
   in `coderd/userauth.go` is a comment, not code, as of 2.36.7 and main).
3. The token is written to the `coder-api-token` Secret and exported as the
   `coder_api_token` output for `iac/coder-template` (the `sentry_auth_token`
   pattern).

The gate is "Secret exists → skip", so re-runs never mint duplicates; delete
the Secret to force rotation. The `tofu-deploy` user appears in the Users page
as an owner — that is expected.

Idempotency: `create-admin-user` is a plain DB INSERT (no upsert, no password
reset — verified against v2.36.7 source) with a fixed username/email, so
duplicate users are impossible (partial-failure reruns tolerate
already-exists); token rows use a unique `token_name` per attempt for the same
reason. The user's password is unusable (password login is blocked
deployment-wide) — the token is its only access.
- `default_ttl_ms` = 8h: workspaces auto-stop after a working day of
  inactivity; restart via dashboard/CLI or autostart schedule.
- **KubeVirt VM workspaces** are wired too — a second template (`kubevirt`,
  managed here in `templates/kubevirt/`) runs full Ubuntu VMs with native
  docker. Persistence mirrors pod workspaces: disposable root (ephemeral
  overlay over a golden image) + persistent `/home/coder` PVC, so every
  start is a pristine first boot — fresh agent token, fresh packages, no
  drift.
- Sizing: single-node cluster — keep template CPU/memory defaults modest.
- KubeVirt VM workspaces: see the bullet above and `../coder-template`'s
  README for the extra infrastructure (golden image, clone-auth, VM RBAC,
  CRD reader).

Creating a workspace: dashboard → Templates → Default (Kubernetes) → Create
workspace, or `coder create --template default <name>`. The default image
(`codercom/example-base:ubuntu`) is minimal; swap the template's `image`
variable for `codercom/example-universal:ubuntu` or a custom build for more
preinstalled tooling.

## Operational notes

- **DB hibernation** (`is_db_hibernate`) takes the whole control plane offline.
  Running workspaces survive and reconnect, but start/stop/template ops fail.
- Upgrades: bump `version` in `coder.tf` (stable channel = N-1 mainline; see
  the [release calendar](https://coder.com/docs/reference/releases)). Apply,
  then restart workspaces if the CLI/agent version skew warns.
- If workspace connections hang behind Traefik/Cloudflare, try
  `CODER_DERP_FORCE_WEBSOCKETS=true` (DERP normally uses `Upgrade: derp`).
- First-run: sign in via Keycloak → owner account. The workspace template is
  deployed by tofu (`../coder-template`), and its API token is auto-minted by
  `bootstrap.tf` — no manual steps.

## Application of this module

Standard flow: commit to trunk → `utils/check-tf-locks.sh` →
`gh workflow run deploy.yml -f runner-type=self-hosted` (`coder` is in the
`deploy-bulk` matrix). No module-specific TF_VARs are required.
