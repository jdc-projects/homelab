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
  Owners retain password login as a lockout escape hatch; `coder server
  create-admin` can recover a fully locked-out deployment.

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

- Kubernetes pod workspaces via Coder's terraform provider; the chart's service
  account can manage pods/PVCs in the `coder` namespace (workspaces land there
  by default).
- Sizing: single-node cluster — keep template CPU/memory defaults modest.
- KubeVirt is installed if VM-based workspaces are ever wanted (template-level
  change + extra SA rules; not wired here).

## Operational notes

- **DB hibernation** (`is_db_hibernate`) takes the whole control plane offline.
  Running workspaces survive and reconnect, but start/stop/template ops fail.
- Upgrades: bump `version` in `coder.tf` (stable channel = N-1 mainline; see
  the [release calendar](https://coder.com/docs/reference/releases)). Apply,
  then restart workspaces if the CLI/agent version skew warns.
- If workspace connections hang behind Traefik/Cloudflare, try
  `CODER_DERP_FORCE_WEBSOCKETS=true` (DERP normally uses `Upgrade: derp`).
- First-run: sign in via Keycloak → owner account → `coder templates create`
  (start from `examples/templates/kubernetes` in coder/coder; use the
  `registry.coder.com/coder/code-server` module with `subdomain = true`).

## Application of this module

Standard flow: commit to trunk → `utils/check-tf-locks.sh` →
`gh workflow run deploy.yml -f runner-type=self-hosted` (`coder` is in the
`deploy-bulk` matrix). No module-specific TF_VARs are required.
