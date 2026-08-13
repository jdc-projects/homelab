# Cap

[Cap](https://trycap.dev) — self-hosted, privacy-first CAPTCHA (proof-of-work +
JS instrumentation). Deploys the official Standalone image (`tiago2/cap`) backed
by a dedicated Valkey release, exposed at `cap.<server_base_domain>`.

## Layout

- `valkey.tf` — dedicated `valkey` Helm release (state store; service DNS
  `valkey:6379`). Mirrors `iac/outline/valkey.tf`.
- `cap.tf` — `ADMIN_KEY` secret (random), the `cap` Deployment
  (`tiago2/cap:3.1.9`, port 3000, UID/fsGroup 1000, GeoIP PVC at
  `/usr/src/app/data`).
- `ingress.tf` — two `modules/ingress` calls (see Ingress below).

## Ingress (two module calls, fail-closed OIDC)

The dashboard is served at the host root (`/`, `/server/*`, `/auth/*`,
`/public/*`, `/swagger`) interleaved with the public CAPTCHA endpoints
(`/<siteKey>/{challenge,redeem}`, `/(siteKey/)?siteverify`, `/assets/*`). Because
`<siteKey>` is dynamic, the host is **default-denied with OIDC** and only the
verified public endpoints are carved out:

- `cap_ingress` — `auth_mode = oidc-interactive`, catch-all (priority 1). Protects
  the dashboard with Keycloak SSO. Creates the `cap-internal` Service + the
  Keycloak client + the `cap-auth-interactive` middleware.
- `cap_public` — `auth_mode = none`, `PathRegexp` for the public endpoints
  (priority 100). Reuses `cap-internal`.

Admin flow: Keycloak login → Cap dashboard → enter `ADMIN_KEY`. Two layers.

Geoblock is disabled on both (challenge endpoints are hit by browsers worldwide);
CrowdSec + Cloudflare remain.

## Observability — intentionally none

Per `AGENTS.md`, signals are omitted when the app can't support them. Verified
against the Cap Standalone source (`standalone/src/`):

- **Tracing**: none. Cap runs on **Bun**; the OTel Operator's auto-instrumentation
  targets nodejs/python/java and cannot be injected into a Bun runtime. No
  `Instrumentation` CR.
- **Errors/Sentry**: Cap bundles no Sentry SDK (`@sentry/*` absent from
  `package.json`). No Sentry wiring.
- **Metrics**: Cap exposes no `/metrics`/`/prometheus` endpoint (the "metrics" in
  its dashboard are internal analytics in Redis, not Prometheus). No
  `ServiceMonitor`/`PodMonitor`. (The Valkey release below does enable its own
  metrics + ServiceMonitor — that is the only metrics source here.)

## CORS

Cap matches CORS origins by **exact string only** — no wildcards, no regex
(`Array.includes` on the `Origin` header). So `https://*.example.com` would never
match and would silently break the widget. The global `CORS_ORIGIN` is therefore
set to `*` (allow-all, credentials-safe reflection). To restrict a site, set its
**concrete origin** (e.g. `https://app.jd-chapman.dev`) on the site key in the
dashboard (Configuration tab → CORS). That per-key list fully replaces the global
default, and adding a subdomain needs no redeploy.

## Operational notes

- Retrieve the admin key:
  `kubectl -n cap get secret cap-env -o jsonpath='{.data.ADMIN_KEY}' | base64 -d`
- Cap must be publicly reachable for the widget to work — it is, via the public
  ingress above.
- `RATELIMIT_IP_HEADER=X-Forwarded-For` is set; Traefik sets that header and the
  service is ClusterIP-only, so trusting it is correct.
