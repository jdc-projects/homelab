# Grafana Tempo — distributed trace backend (tempo-distributed chart).
#
# Storage: an inline RustFS instance (this module) provides the S3 backend,
# matching the per-service RustFS convention used by terraform/outline and
# terraform/posthog. The bucket is created by kubernetes_job.rustfs_provision
# BEFORE this release installs (see depends_on below), so Tempo always starts
# against an existing bucket. This avoids the bundled-MinIO chicken-and-egg
# (bucket created by a post-install hook that only runs after Tempo pods are
# ready -> deadlock under helm --wait) and lets the release ship with the
# standard `wait = true`.
#
# Receivers: the distributor accepts OTLP grpc (4317) + http (4318); the
# OpenTelemetryCollector (terraform/otel-collector/) exports traces here.
# Grafana queries the query-frontend HTTP API on :3200 (see
# grafana-datasource.tf).
resource "helm_release" "tempo" {
  name = "tempo"

  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo-distributed"
  version    = "1.61.3"

  namespace = kubernetes_namespace.tempo.metadata[0].name

  # Safe because the tempo-traces bucket is guaranteed to exist before this
  # release installs (kubernetes_job.rustfs_provision in depends_on). Helm
  # waits for all Tempo pods to be ready; no deadlock.
  wait    = true
  timeout = 600

  set = [
    # --- Receivers: OTLP grpc + http on the distributor ---------------------
    {
      name  = "traces.otlp.grpc.enabled"
      value = "true"
    },
    {
      name  = "traces.otlp.http.enabled"
      value = "true"
    },

    # --- Storage: inline RustFS instance as the S3 backend ------------------
    {
      name  = "storage.trace.backend"
      value = "s3"
    },
    {
      name  = "storage.trace.s3.bucket"
      value = local.rustfs_bucket_name
    },
    {
      name  = "storage.trace.s3.endpoint"
      value = "rustfs-svc:9000"
    },
    {
      name  = "storage.trace.s3.insecure"
      value = "true"
    },

    # --- Ingester WAL on a PVC so in-flight traces survive restarts ---------
    {
      name  = "ingester.persistence.enabled"
      value = "true"
    },
    {
      name  = "ingester.persistence.size"
      value = "10Gi"
    },
    {
      name  = "ingester.persistence.storageClass"
      value = "openebs-zfs-localpv-random-no-backup"
    },

    # --- Single-node footprint (replication_factor must follow replicas) ----
    {
      name  = "ingester.replicas"
      value = "1"
    },
    {
      name  = "ingester.config.replication_factor"
      value = "1"
    },

    # --- Retention: 14d -----------------------------------------------------
    {
      name  = "compactor.config.compaction.block_retention"
      value = "336h"
    },

    # --- Self-monitoring scraped by the select-all Prometheus ---------------
    {
      name  = "metaMonitoring.serviceMonitor.enabled"
      value = "true"
    },
  ]

  set_sensitive = [
    # RustFS root creds are reused as Tempo's S3 access/secret keys
    # (single-tenant homelab -> no separate app user), matching the outline
    # RustFS pattern.
    {
      name  = "storage.trace.s3.access_key"
      value = random_password.rustfs_root_username.result
    },
    {
      name  = "storage.trace.s3.secret_key"
      value = random_password.rustfs_root_password.result
    },
  ]

  # Bucket must exist before Tempo installs, else Tempo crash-loops at startup
  # ("bucket does not exist") and helm --wait deadlocks.
  depends_on = [kubernetes_job.rustfs_provision]
}
