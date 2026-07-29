locals {
  # =========================================================================
  # PostHog application images
  # =========================================================================

  # PostHog Django image.
  # Tags:      https://hub.docker.com/r/posthog/posthog/tags  (sha-<short> tags)
  # Changelog: https://github.com/PostHog/posthog/releases
  posthog_image = "posthog/posthog:sha-9c93bdd"

  # Node.js plugin-server image.  PostHog CI publishes this from a *different*
  # commit than the Django image, so the short SHA will not match
  # posthog_image above.  There is no matching tag on GHCR — use Docker Hub.
  # Source: https://hub.docker.com/r/posthog/posthog-node/tags
  posthog_node_img = "posthog/posthog-node:sha-c280973"

  # Rust service images.  GHCR publishes no human-readable tags for these —
  # only digests.  To find the digest for a target PostHog commit, check the
  # package page for each service.
  # Source: https://github.com/orgs/PostHog/packages?repo_name=posthog
  rust_images = {
    capture           = "ghcr.io/posthog/posthog/capture@sha256:f0deecf3312e98262ed936dd28899f1b412e19e23184177bf8fb469b2472fb98"
    capture-logs      = "ghcr.io/posthog/posthog/capture-logs@sha256:6876b2c649de7044a696fbbbf010a6961fe73444f4df7e6a43b74c34b7218524"
    property-defs-rs  = "ghcr.io/posthog/posthog/property-defs-rs@sha256:b0c026b733d180ce61bdbeb47d897bca3c3a3312df3c2b1124e15d704d063a44"
    feature-flags     = "ghcr.io/posthog/posthog/feature-flags@sha256:97e4dfeed9770be6cbd70c6422c7d72b566409e3f15a50c57dfd3f61c32366cc"
    personhog-replica = "ghcr.io/posthog/posthog/personhog-replica@sha256:fd422303574fdaacdbea01483c5da32187804b80dac837a777b8f441f8e8527a"
    personhog-router  = "ghcr.io/posthog/posthog/personhog-router@sha256:ab7785063ae39d15bff1b4cc4e64ef4090a0d03575405f196d6a9cee863f9719"
    hypercache-server = "ghcr.io/posthog/posthog/hypercache-server@sha256:fefa0347d51f76046428c069b9b5969259e3780f9d201da2f8aa6ec1d50722c4"
    cyclotron-janitor = "ghcr.io/posthog/posthog/cyclotron-janitor@sha256:78fa637098d5109d16ea758134e9fda9cc2e87a8177f95c8d1daa70525718fdd"
    livestream        = "ghcr.io/posthog/posthog/livestream@sha256:3707cf5ae7ce91a2f14ccdd2c81b042e8276308cdc77f8e0bce6c4e4c42c3630"
    cymbal            = "ghcr.io/posthog/posthog/cymbal@sha256:d1f04ec3a0cc93099bf41cf0d86da1c6074362e5a61607ab1a3e572f3a19c0fa"
  }

  # =========================================================================
  # Infrastructure images
  # =========================================================================

  # ClickHouse SSE2-baseline build for Ivy Bridge nodes (no AVX2).
  # The upstream ClickHouse binary requires AVX2; this image provides a
  # compatible build of the same version.
  # Source: https://github.com/jdc-projects/clickhouse-compat
  clickhouse_compat_image = "ghcr.io/jdc-projects/clickhouse-compat:compat-2c267f1f2f48-img-1.0.0"

  # CloudNative-PG Postgres image.
  # Tags: https://github.com/cloudnative-pg/postgresql-containers/pkgs/container/postgresql
  postgres_image = "ghcr.io/cloudnative-pg/postgresql:16.14-standard-trixie"

  # Browserless — headless Chromium for heatmap screenshots.
  # Releases: https://github.com/browserless/browserless/releases
  browserless_image = "ghcr.io/browserless/chromium:v2.51.2"

  # MinIO mc client — used in RustFS bucket provisioning jobs.
  # Releases: https://github.com/minio/mc/releases
  minio_mc_image = "minio/mc:RELEASE.2025-08-13T08-35-41Z"

  # kubectl image for GeoIP download Job/CronJob.
  # https://hub.docker.com/r/alpine/kubectl/tags
  kubectl_image = "alpine/kubectl:1.33.4"

  # =========================================================================
  # Helm chart versions
  # =========================================================================

  # Valkey chart.
  # https://valkey.io/valkey-helm/
  valkey_chart_version = "0.10.0"

  # RustFS chart (used for both object storage and session recordings).
  # https://charts.rustfs.com/
  rustfs_chart_version = "0.9.0"

  # =========================================================================
  # CR-based application versions
  # =========================================================================

  # Kafka version (Strimzi Kafka CR spec.kafka.version).
  # Releases: https://kafka.apache.org/downloads
  kafka_version = "4.1.0"

  # OpenSearch version (OpenSearchCluster CR spec.general.version).
  # Releases: https://opensearch.org/downloads.html
  opensearch_version = "2.13.0"
}
