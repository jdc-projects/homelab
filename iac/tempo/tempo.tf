# Grafana Tempo — distributed trace backend (tempo-distributed chart).
#
# Storage: an inline RustFS instance (this module) provides the S3 backend,
# matching the per-service RustFS convention used by iac/outline and
# iac/posthog. The bucket is created by kubernetes_job.rustfs_provision
# BEFORE this release installs (see depends_on below), so Tempo always starts
# against an existing bucket. This avoids the bundled-MinIO chicken-and-egg
# (bucket created by a post-install hook that only runs after Tempo pods are
# ready -> deadlock under helm --wait) and lets the release ship with the
# standard `wait = true`.
#
# Receivers: the distributor accepts OTLP grpc (4317) + http (4318); the
# OpenTelemetryCollector (iac/otel-collector/) exports traces here.
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

    # --- Metrics generator --------------------------------------------------
    # Powers Grafana Traces Drilldown: TraceQL metrics queries (rate(),
    # latency histograms) and the generated span/service-graph metrics are
    # produced by this component. Without it those queries fail with
    # "error finding generators: empty ring".
    {
      name  = "metricsGenerator.enabled"
      value = "true"
    },
    {
      name  = "metricsGenerator.replicas"
      value = "1"
    },
    # The chart defaults to a REQUIRED podAntiAffinity (spread replicas across
    # nodes). On this single-node cluster that deadlocks rolling updates - the
    # surge pod can't schedule while the old pod runs. Empty disables it, same
    # pattern as the affinity overrides in iac/grafana/loki.tf.
    {
      name  = "metricsGenerator.affinity"
      value = ""
    },
    # Run the metrics-generator as a StatefulSet (not the default Deployment):
    # a 1-replica StatefulSet rolls by terminating pod-0 then recreating it
    # (no two pods coexist), so rolling updates never trip the anti-affinity
    # rule on this single node. Also makes the persistence PVC below apply
    # properly (volumeClaimTemplate) instead of a Deployment's emptyDir.
    {
      name  = "metricsGenerator.kind"
      value = "StatefulSet"
    },
    # WAL PVC so metrics-generator state survives restarts (matches ingester).
    {
      name  = "metricsGenerator.persistence.enabled"
      value = "true"
    },
    {
      name  = "metricsGenerator.persistence.size"
      value = "10Gi"
    },
    {
      name  = "metricsGenerator.persistence.storageClass"
      value = "openebs-zfs-localpv-random-no-backup"
    },

    # --- Self-monitoring scraped by the select-all Prometheus ---------------
    {
      name  = "metaMonitoring.serviceMonitor.enabled"
      value = "true"
    },
  ]

  # Per-tenant enablement: route traces to the metrics-generator with all three
  # processors. The chart deploys the component on metricsGenerator.enabled
  # but does NOT enable generation per tenant - without this the empty-ring
  # error clears but the queries return nothing. (Chart README:767,1140.)
  #   - local-blocks:  powers the TraceQL metrics-query API (rate(),
  #                    quantile_over_time) that Grafana Traces Drilldown uses.
  #                    Without it Drilldown errors "localblocks processor not
  #                    found" (after the ring is populated).
  #   - service-graphs: powers the service-graph / topology views.
  #   - span-metrics:   classic RED metrics -> Prometheus (traces_spanmetrics_*).
  set_list = [
    {
      name = "overrides.defaults.metrics_generator.processors"
      value = [
        "local-blocks",
        "service-graphs",
        "span-metrics",
      ]
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
