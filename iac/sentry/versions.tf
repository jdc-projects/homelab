locals {
  # =========================================================================
  # Sentry application images
  # =========================================================================

  # Sentry Django image.
  # Custom image with OIDC SSO (Keycloak) via the sentry-auth-oidc plugin.
  # Source: https://github.com/jdc-projects/sentry-oidc
  sentry_image = "ghcr.io/jdc-projects/sentry-oidc:sentry-26.7.1-oidc-9.1.1"

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

  # MinIO mc client — used in RustFS bucket provisioning jobs.
  # Releases: https://github.com/minio/mc/releases
  minio_mc_image = "minio/mc:RELEASE.2025-08-13T08-35-41Z"

  # kubectl image for ClickHouse provisioning job.
  # https://hub.docker.com/r/alpine/kubectl/tags
  kubectl_image = "alpine/kubectl:1.33.4"

  # =========================================================================
  # Helm chart versions
  # =========================================================================

  # Sentry chart (sentry-kubernetes/charts).
  # https://github.com/sentry-kubernetes/charts
  sentry_chart_version = "33.1.0"

  # Valkey chart.
  # https://valkey.io/valkey-helm/
  valkey_chart_version = "0.10.0"

  # RustFS chart (object storage).
  # https://charts.rustfs.com/
  rustfs_chart_version = "0.9.0"

  # =========================================================================
  # CR-based application versions
  # =========================================================================

  # Kafka version (Strimzi Kafka CR spec.kafka.version).
  # Releases: https://kafka.apache.org/downloads
  kafka_version = "4.1.0"
}
