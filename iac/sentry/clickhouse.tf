# Single-node Altinity ClickHouse for Sentry (Snuba).
#
# Uses the AVX2-compat ClickHouse image (Ivy Bridge baseline build) via
# local.clickhouse_compat_image. Sentry's Snuba connects via the "clickhouse"
# Service (http 8123 / tcp 9000); the application database + user are created
# by the clickhouse-provision Job (the Altinity operator does not reliably
# materialise users from the CHI users map).

locals {
  # Compat: restore pre-26.6 merge_tree validation behaviour. The compat
  # ClickHouse build (and upstream 26.x) rejects AggregatingMergeTree tables
  # whose non-aggregate columns aren't in the sorting key; Snuba's migrations
  # create such tables (e.g. generic_metrics 0041), so this MUST be enabled or
  # snuba-migrate fails. Mirrors the PostHog module's compat setting
  # (iac/posthog/clickhouse.tf posthog_compat_xml).
  sentry_compat_xml = <<-XML
    <clickhouse>
      <merge_tree>
        <allow_dimensions_outside_sorting_key>1</allow_dimensions_outside_sorting_key>
      </merge_tree>
    </clickhouse>
  XML
}

resource "kubernetes_manifest" "sentry_clickhouse" {
  manifest = {
    apiVersion = "clickhouse.altinity.com/v1"
    kind       = "ClickHouseInstallation"

    metadata = {
      name      = "sentry-ch"
      namespace = local.ns
    }

    spec = {
      defaults = {
        templates = {
          podTemplate             = "clickhouse"
          dataVolumeClaimTemplate = "data"
          serviceTemplate         = "chi-service"
        }
      }

      configuration = {
        clusters = [
          {
            name   = "sentry"
            layout = { shardsCount = 1, replicasCount = 1 }
          }
        ]

        files = {
          "sentry-compat.xml" = local.sentry_compat_xml
        }

        users = {
          default = {
            password          = ""
            networks          = { ip = "::/0" }
            access_management = 1
          }
          sentry = {
            password          = ""
            networks          = { ip = "::/0" }
            access_management = 1
          }
        }
      }

      templates = {
        podTemplates = [
          {
            name = "clickhouse"
            spec = {
              containers = [
                {
                  name  = "clickhouse"
                  image = local.clickhouse_compat_image
                  resources = {
                    requests = { cpu = "1", memory = "3Gi" }
                    limits   = { cpu = "3", memory = "6Gi" }
                  }
                }
              ]
            }
          }
        ]

        volumeClaimTemplates = [
          {
            name          = "data"
            reclaimPolicy = "Delete"
            spec = {
              storageClassName = "openebs-zfs-localpv-bulk-no-backup"
              accessModes      = ["ReadWriteOnce"]
              resources = {
                requests = { storage = "20Gi" }
              }
            }
          }
        ]

        serviceTemplates = [
          {
            name = "chi-service"
            spec = {
              type = "ClusterIP"
              ports = [
                { name = "http", port = 8123 },
                { name = "tcp", port = 9000 }
              ]
            }
          }
        ]
      }
    }
  }

  field_manager {
    force_conflicts = true
  }

  computed_fields = [
    "metadata.labels",
    "metadata.annotations",
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_service" "clickhouse" {
  metadata {
    name      = "clickhouse"
    namespace = local.ns
  }

  spec {
    selector = {
      "clickhouse.altinity.com/chi" = "sentry-ch"
    }

    port {
      name = "http"
      port = 8123
    }

    port {
      name = "tcp"
      port = 9000
    }
  }

  depends_on = [kubernetes_manifest.sentry_clickhouse]
}
