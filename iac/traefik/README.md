# traefik

The shared edge: Traefik (DaemonSet, hostNetwork, chart pinned in
`traefik.tf`) terminating TLS for `*.jd-chapman.dev`, plus the cert-manager
`Certificate/wildcard` → secret `wildcard-cert` it serves as the default TLS
store certificate.

## Observability

- **Metrics**: chart-provided ServiceMonitor (`metrics.prometheus.serviceMonitor.enabled`), scraped as job `traefik-metrics`.
- **Alerts**: `EdgeTLSCertExpiringSoon` (`prometheusrule.tf`) — warning, `for: 1h`, fires when the newest edge certificate per CN expires within 14d. Stale-serial-proof; see below.
- **Dashboards**: `dashboards/` via `modules/grafana-dashboard`.
- **Tracing**: OTLP to the OTel collector (chart values in `traefik.tf`).

## Ghost TLS-cert metric series (traefik/traefik#8606)

Traefik never deletes the `traefik_tls_certs_not_after` gauge series of a
replaced certificate. Each in-place cert-manager renewal of the wildcard
(LE 90d certs → ~quarterly; **next renewal ~2026-10-18**) leaks one ghost
series carrying the old serial and its stale `notAfter`. The edge still
serves the correct new cert on the wire — it is purely a metrics artifact.

Implications and mitigations:

- **Alerting**: `EdgeTLSCertExpiringSoon` dedupes per `(cn, sans)` with
  `max` before taking the `min`, so ghost series can't false-fire it. Plain
  `min(traefik_tls_certs_not_after)` (e.g. xitter's old
  `XitterCertExpiringSoon`) false-positives ~2 weeks after every renewal.
- **Series cleanup**: a Traefik pod restart drops the leaked series.
  `deployment.podAnnotations.homelab/restartedAt` in `traefik.tf` forces the
  rolling restart — **bump its timestamp after each renewal** (or whenever
  the ghost series is observed) until a fixed release ships. Expect a few
  seconds of edge downtime on apply (maxUnavailable=1, single node).

## Upstream watch — plan a bump when a fix ships

- Issue: [traefik/traefik#8606](https://github.com/traefik/traefik/issues/8606) (open).
- Proposed fixes: PR
  [traefik/traefik#11659](https://github.com/traefik/traefik/pull/11659)
  (reset stale series to 0 — open, stalled in design review since 2025) and
  commit `394a496` ("remove tls certificate metrics when certs are deleted
  from config").
- **Neither is merged into any release as of 2026-09-11** — `394a496` was
  verified absent from v3.7.13 (latest at the time). Before relying on a
  bump, verify the fix is actually merged *and* in a released tag
  (`git branch -r --contains 394a496`, changelog / release notes), then bump
  the chart pin in `traefik.tf` and retire the restartedAt bump habit.
