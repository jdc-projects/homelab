# clickhouse-operator

Any `ClickHouseInstallation` in this cluster must use the compat image
(`ghcr.io/jdc-projects/clickhouse-compat`) instead of the official
`clickhouse-server` image. See
[jdc-projects/clickhouse-compat](https://github.com/jdc-projects/clickhouse-compat)
for the current tag, the reason, and caveats.
