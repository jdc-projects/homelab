# huly

[Huly](https://huly.io) — open-source project management platform (Linear/Jira/
Slack/Notion replacement). Deployed via the official Helm chart
(`oci://ghcr.io/hcengineering/charts/huly`) with the chart's bundled
infrastructure dependencies swapped for cluster-native equivalents.

## Architecture

| Layer | Implementation | Module pattern |
|---|---|---|
| Database | CNPG Postgres 16 | `postgres.tf` (mirrors `outline/postgres.tf`, native hibernate via `cnpg.io/hibernation` annotation) |
| Queue | Strimzi Kafka 4.1.0 | `kafka.tf` (mirrors `posthog/kafka.tf`, stripped down) |
| Search | ECK-managed Elasticsearch 7.17.29 | `elasticsearch.tf` + the `elasticsearch-operator` module |
| Object storage | RustFS (MinIO replacement) | `rustfs.tf` + `rustfs-provision.tf` (mirrors `outline/rustfs*.tf`) |
| SSO | Keycloak OIDC (via Huly) + traefik-oidc-auth gateway on `/_accounts/*` and `/` (gates the open `signUp` RPC) | `keycloak.tf` + `ingress.tf` |
| Ingress | Traefik IngressRoute path routing via `modules/ingress` | `ingress.tf` (mirrors `posthog/ingress.tf`'s `for_each`) |
| Tracing | OTel auto-instrumentation via opentelemetry-operator | `instrumentation.tf` + `post-renderer.sh` (chart-managed pods) |

The Huly `@hcengineering/postgres` driver is Postgres-native (PL/pgSQL
migrations, JSONB ops CRDB only partially supports), so CNPG works as a
drop-in for the bundled CockroachDB — verified at the source level. The
Huly `kafkajs` client speaks the standard Kafka wire protocol, so Strimzi
Kafka works as a drop-in for the bundled Redpanda. The Huly
`@elastic/elasticsearch@^7.17` JS client requires real ES (not OpenSearch)
because of the client's product-check — see
[`elasticsearch-operator/README.md`](../elasticsearch-operator/README.md)
for the version-pin rationale and the TLS/auth posture.

## Services deployed

| Service | Port | Purpose |
|---|---|---|
| `front` | 8080 | Web UI (catch-all `/`) |
| `account` | 3000 | Auth (handles OIDC callbacks at `/_accounts/auth/openid/callback`) |
| `transactor` | 3333 | Core transaction engine (WebSocket, `/_transactor`) |
| `collaborator` | 3078 | Real-time co-editing (WebSocket, `/_collaborator`) |
| `workspace` | — | Workspace lifecycle (background worker) |
| `fulltext` | 4700 | Search indexing (consumes Kafka, writes to ES) |
| `rekoni` | 4004 | Content extraction (binaries → text) |
| `stats` | 4900 | Metrics collection |
| `kvs` | 8094 | Key-value store |

All exposed under a single FQDN (`huly.<server_base_domain>`) via Traefik
path-based routing with `StripPrefix` middlewares (the chart's NGINIX
equivalent uses `rewrite-target: /$2`; we replicate the prefix-stripping
behaviour).

## Auth posture

Huly's `DISABLE_SIGNUP` env var (chart value `auth.disableSignup`) couples
two behaviours via a single boolean in the source
(`hcengineering/platform/server/account-service/src/index.ts`):

1. **OIDC auto-provisioning** — creating a Huly account on first successful
   Keycloak login. Without this, no Keycloak user can log in (chicken-and-egg).
2. **The `signUp` RPC method** at `POST /_accounts/` — open to anyone, no
   email confirmation required (chart doesn't set `MAIL_URL`).

We need (1) and don't want (2), but the upstream flag can't separate them.
The workaround: keep `disableSignup=false` (so OIDC works) and gate the
`/_accounts/*` paths at the ingress layer with `traefik-oidc-auth`
(`auth_mode = "oidc-interactive"` in `ingress.tf`). Only Keycloak-authenticated
users can reach `signUp`. The `/_accounts/auth/*` paths (Huly's own OIDC
start + callback) are exempt to avoid breaking the OIDC bootstrap, and the
front catch-all `/` is gated so a gateway session exists before the SPA
makes its first RPC. See `ingress.tf`'s top-of-file comment for the full
flow + update-guard checklist.

## Hibernation

| Component | Mechanism |
|---|---|
| Postgres | CNPG native — `cnpg.io/hibernation` annotation toggled by `is_db_hibernate` |
| Kafka | Picked up by the existing `hibernate-kafka-*` jobs in `databases-hibernate.yml` (matrix auto-discovers `Kafka` CRs across namespaces) |
| Elasticsearch | Picked up by the `hibernate-elasticsearch-*` jobs in `databases-hibernate.yml` (added alongside the operator module) |
| RustFS | Not hibernated (stateless object store with PVC; matches outline's pattern) |

Alertmanager silencing is also wired: namespaces containing ES CRs are
included in `alertmanager-silence.yml`'s CRD discovery list.

## Optional add-ons (NOT enabled)

These can be enabled by editing `huly.tf` — document here for the next
person. All are upstream-supported but were skipped for the v1 deployment
per scope decisions.

### GitHub integration (bidirectional issue/PR sync)

Set `githubIntegration.enabled = true` in `huly.tf` and provide a GitHub
App's credentials (`githubIntegration.appId/clientId/clientSecret/privateKey/
webhookSecret/botName`). Requires creating a GitHub App under the
`jdc-projects` org with the permissions documented in the upstream chart's
README. Adds a new `/_github` ingress path.

### AI bot

Set `aibot.enabled = true` in `huly.tf` and provide `secrets.openaiApiKey`
(usually via a `TF_VAR_openai_api_key` GitHub Actions secret). Adds a MongoDB
dependency (chart-managed). Adds a new `/_aibot` ingress path.

### Audio/video (virtual office)

Requires an external [LiveKit](https://livekit.io) Cloud account — Huly uses
LiveKit SaaS, not a self-hostable SFU. Configure `love.*` values if/when
LiveKit credentials exist. Adds a `/_love` ingress path.

### Additional auth providers (alongside Keycloak OIDC)

Set `auth.google.clientId/Secret` and/or `auth.github.clientId/Secret` to
show extra login buttons on the Huly login screen. Keycloak remains the
primary IdP; Google/GitHub would be alternative direct OAuth paths.

## Useful operational commands

```bash
# Watch all Huly pods
kubectl -n huly get pods -l app.kubernetes.io/part-of=huly

# Tail fulltext logs (Kafka + ES connections live here)
kubectl -n huly logs -l app=fulltext -f

# Inspect the auto-generated elastic password (for direct ES curl debugging)
kubectl -n huly get secret elastic-es-elastic-user -o jsonpath='{.data.elastic}' | base64 -d

# Reconcile the helm release after editing values
tofu -chdir=iac/huly apply -replace=helm_release.huly

# OIDC smoke test (should return 302 to idp.<domain>)
curl -sI https://huly.<server_base_domain>/_accounts/auth/openid | head -5
```

## Pinning / versioning

| Component | Pinned version | Where |
|---|---|---|
| Huly chart | `0.1.0` | `huly.tf` `helm_release.huly.version` |
| Huly app images | `v0.7.432` | `huly.tf` `set.hulyVersion` |
| Postgres | `ghcr.io/cloudnative-pg/postgresql:16.14-standard-trixie` | `postgres.tf` |
| Kafka | `4.1.0` | `kafka.tf` `local.kafka_version` |
| Elasticsearch | `7.17.29` | `elasticsearch.tf` `spec.version` |
| RustFS chart | `0.9.0` | `rustfs.tf` |

The Huly chart is pinned to `0.1.0` because that's the only published OCI
version as of writing. The app version `v0.7.432` is a stable upstream tag
(avoid `s*` tags — those are dev pre-releases).

## Post-renderer (`post-renderer.sh`)

The chart has two limitations this module works around via a helm
`postrender` hook:

1. **URL scheme coupling with `ingress.enabled`**: the chart's `configmap.yaml`
   derives browser-facing URL schemes (`http`/`https`, `ws`/`wss`) from
   `ingress.enabled && ingress.tls.enabled`. We set `ingress.enabled=false`
   (we use `modules/ingress`, not chart-managed Ingress resources), so the
   chart would produce `http://`/`ws://` URLs in `/config.json` — which
   browsers refuse from an HTTPS page (mixed content). The post-renderer
   rewrites `http://<domain>` → `https://<domain>` and `ws://<domain>` →
   `wss://<domain>` in the chart's ConfigMap. Internal URLs
   (`http://account:3000` etc.) are untouched because they don't include
   the public domain.

2. **No pod-annotation hook**: chart-managed Deployments can't be annotated
   via values, but the opentelemetry-operator's inject mechanism needs
   `instrumentation.opentelemetry.io/inject-nodejs: "true"` on the pod
   template. The post-renderer adds it to every chart-rendered Deployment.
   The `Instrumentation` CR (in `instrumentation.tf`) makes the operator
   actually inject the Node.js SDK + exporter env vars at admission time.

The script is pattern-based (looks for `kind: ConfigMap` with the chart's
ConfigMap name; `kind: Deployment` resources). If a future chart version
renames either, the patches silently no-op rather than crash — re-test after
chart version bumps.

## Observability

| Signal | Status | Notes |
|---|---|---|
| Tracing | ✅ Wired | `Instrumentation` CR (`instrumentation.tf`) + pod annotation via `post-renderer.sh`. Huly's own `@hcengineering/elastic` also bundles OTel SDK; once the env vars are present (set by the operator at admission) both layers export to the otel-collector. |
| Metrics | ❌ N/A | Huly services don't expose `/metrics` or `/prometheus` endpoints (verified by probing). No ServiceMonitor/PodMonitor configured. |
| Errors (Sentry) | ❌ N/A | Huly doesn't bundle Sentry SDK and the chart exposes no Sentry env vars (verified by grepping chart templates and runtime env). |
| Logs | ✅ stdout | Captured by the existing Loki stack. |

If a future Huly version adds a metrics endpoint or Sentry support, wire it
up and remove the relevant "N/A" line above.
