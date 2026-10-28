# OpenBao

[OpenBao](https://openbao.org) (MPL-licensed Vault fork) — secrets store for
applications, fronted by Keycloak OIDC for human logins.

- **URL**: `https://bao.<domain>` (UI + API; CLI via `bao login -method=oidc`)
- **Storage**: `postgresql` backend on the `openbao-db` CNPG cluster
  (production-ready since 2.x, HA-capable as of 2.7.0). OpenBao's docs
  recommend PostgreSQL as the easier-to-operate backend vs Raft, and it keeps
  this module on the standard per-service CNPG pattern (volumeSnapshot
  backups, velero-excluded, participates in the nightly hibernation workflow).
- **Deployment**: official `openbao` helm chart, standalone / 1 replica — HA
  is pointless on a single-node cluster. Chart's injector/CSI are off (below).
- **Config**: `iac/openbao-config` (Keycloak client, OIDC + Kubernetes auth
  methods, policies, KV mount, audit device) via the `hashicorp/vault`
  OpenTofu provider, mirroring `keycloak`/`keycloak-config`.

## Sealing & bootstrap (no manual unsealing)

There is no cloud KMS/HSM here, so Shamir is the only seal — but every step is
automated in-cluster (nothing passes through tofu state or the runner):

1. `kubernetes_job.openbao_bootstrap` (this module) waits for the API, runs
   `bao operator init -key-shares=1 -key-threshold=1` exactly once, and stores
   the results as Secrets in this namespace:
   - `openbao-seal` (`unseal-key`) — consumed by the **unseal sidecar**
     (`server.extraContainers`), which re-unseals on every pod start,
     chart upgrade, node reboot, and hibernation wake.
   - `openbao-bootstrap` (`root-token`) — read once to seed
     `iac/openbao-config` (see below).
2. Steady state is fully self-healing; `updateStrategyType = RollingUpdate`.

Threat model: the unseal key lives in the same trust domain as every other
secret in this cluster (k8s Secrets + TF state). OpenBao still meaningfully
raises the bar vs plain k8s Secrets for app-level compromise and
backup/DB-snapshot exfiltration. Protection *against cluster-admin
compromise* would require real auto-unseal (cloud KMS / HSM via the `seal`
stanza) — the escape hatch if that ever matters.

Break-glass: store a copy of the unseal key in Vaultwarden (`kubectl -n
openbao get secret openbao-seal -o jsonpath='{.data.unseal-key}' | base64 -d`).
If the cluster dies, CNPG snapshots restore the ciphertext — the key restores
access.

## One-time (and only) manual step

Feed the root token to CI for `iac/openbao-config`:

```bash
kubectl -n openbao get secret openbao-bootstrap -o jsonpath='{.data.root-token}' \
  | base64 -d | gh secret set OPENBAO_ROOT_TOKEN
```

## Hibernation

`openbao-db` is auto-discovered by the nightly hibernation workflow like every
other CNPG cluster (deliberate). OpenBao cannot serve while its DB is asleep
and recovers automatically on wake (`max_connect_retries = 0` + unseal
sidecar); if its pod restarts mid-hibernation the sidecar retries until the
DB is back.

## Observability

- **Metrics**: `telemetry` listener + `serverTelemetry.serviceMonitor` →
  Prometheus; Grafana dashboard vendored from the chart
  (`dashboards/openbao.json`, datasource pinned to `Prometheus`).
- **Tracing**: not supported upstream — OpenBao's OTel migration is
  metrics-only so far (and no OTel-operator auto-instrumentation for Go).
  Revisit when OpenBao grows OTLP export.
- **Sentry**: no SDK in OpenBao — skip (noted here so it isn't re-searched).

## TODO / deferred

- **Switch to the dedicated `openbao` OpenTofu provider once it ships**
  (currently an accepted RFC — a low-divergence soft-fork of
  `hashicorp/vault`; migrate with `tofu state replace-provider`).
  Until then `hashicorp/vault` covers everything this repo uses.
- **Agent injector: purposefully not deployed.** The intended consumers are
  applications (via Kubernetes auth / API), not cluster pods. Enable
  `injector` and wire its k8s-auth role when the first consumer lands.
- **Harden `iac/openbao-config` provider auth**: replace the root token with
  Kubernetes-auth (`kubectl create token` for a dedicated SA in a workflow
  pre-step) and revoke the root token (`bao token revoke`).
- **HSM/KMS auto-unseal** if the threat model ever needs it.
