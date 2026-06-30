# Terraform upgrade follow-ups

Items deferred, blocked, or needing future action from the application/provider
upgrade work. Each has context + links so the next pass can pick them up easily.

## OCIS — chart pinned at ocis 7.1.4 (no 8.x chart exists)

`terraform/ocis/ocis.tf` pins a commit on `owncloud/ocis-charts` `main`.

- The ocis **app** is at 8.x, but the chart (experimental, "not yet published")
  is still `appVersion: 7.1.4` — it cannot deploy ocis 8.x.
- Action: when the maintainers cut an 8.x chart, update `commit_sha` (and drop
  the local git-clone workaround if they finally publish versioned releases).
- Track:
  - https://github.com/owncloud/ocis-charts/commits/main/
  - https://github.com/owncloud/ocis-charts/issues/937 (Add Helm Release Workflow)

## MinIO — upstream archived; will be removed from the Loki chart

MinIO Inc. archived the AGPLv3 `minio/minio` and `minio/operator` repos in favour
of AIStor. The `charts.min.io` chart is frozen (ships a Dec-2024 image, receives
no updates). We use it in **two** places, both at chart `5.4.0`:

- `terraform/outline/minio.tf` — standalone chart for Outline object storage.
- `terraform/grafana/loki.tf` — the bundled `minio` subchart (`minio.enabled=true`).

Grafana Labs has **no plan** to replace it, but the **community-maintained** Loki
chart (forked to `grafana-community/helm-charts` on 2026-03-16) will deprecate
and remove the built-in MinIO subchart:

- A render-time guard makes `minio.enabled=true` **fail** unless
  `ignoreMinioDeprecation=true` is set — shipping as a breaking change in
  **Loki chart 14.0.0**.
- Recommended path: external object storage (S3/GCS/Azure) via a schema-based
  cutover (no in-place data migration; keep old store readable until retention
  ages it out), or a self-hosted S3-compatible alternative (**RustFS**, **Garage**).
- We already use Backblaze B2 for Velero — credentials exist if we go external.
- Links:
  - https://github.com/grafana/loki/issues/19563 (no pre-built images / unpatched CVE)
  - https://github.com/grafana-community/helm-charts/issues/348 (replace minio)
  - https://github.com/grafana-community/helm-charts/issues/366 (deprecate built-in minio + migration path)
  - https://github.com/minio/minio (archived)

Action: before adopting the community Loki chart ≥ 14.0.0, migrate Outline and
Loki off the bundled/standalone MinIO (external S3, or RustFS/Garage in-cluster).

## OpenLDAP image — frozen at 2.6.10

`terraform/openldap/openldap.tf` uses `ghcr.io/open-bitnami/containers/openldap:2.6.10`.

- Upstream OpenLDAP is at 2.6.13, but the `open-bitnami` fork has only published
  up to `2.6.10`. Already at the fork's latest.
- Action: monitor the fork for newer tags, or switch to another OpenLDAP image source.
