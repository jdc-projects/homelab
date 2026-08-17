# PostHog

Self-hosted PostHog with in-cluster dependencies (CloudNative-PG, Valkey,
Strimzi Kafka, Altinity ClickHouse, OpenSearch, RustFS, Temporal) and Keycloak
OIDC SSO.

## Backup scope (velero)

Only the CNPG Postgres config DB (`posthog-db`, `temporal-db`, on
`openebs-zfs-localpv-random`) is backed up — Postgres holds orgs, projects,
users, dashboards, flags (all manual config). ClickHouse, Kafka, OpenSearch and
RustFS volumes use `openebs-zfs-localpv-bulk-no-backup` (skipped via the velero
resource-policy): analytics data and session recordings are treated as
disposable in DR. After a restore, Postgres comes back populated and
ClickHouse/Kafka/OpenSearch come back empty (schema + topics re-provisioned by
the operators/jobs).
