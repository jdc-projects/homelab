locals {
  # Source: PostHog docker/clickhouse/config.d/default.xml
  # Defines PostHog's ClickHouse clusters, Kafka named_collections, and macros.
  # The host is "clickhouse" (resolved to 127.0.0.1 via hostAliases on the pod)
  # so that ON CLUSTER DDL queries execute locally without network roundtrips.
  # Update from: https://github.com/PostHog/posthog/blob/master/docker/clickhouse/config.d/default.xml
  posthog_clusters_xml = <<-XML
    <clickhouse>

        <remote_servers>
            <posthog>
                <shard>
                    <replica>
                        <host>clickhouse</host>
                        <port>9000</port>
                    </replica>
                </shard>
            </posthog>
            <posthog_single_shard>
                <shard>
                    <replica>
                        <host>clickhouse</host>
                        <port>9000</port>
                    </replica>
                </shard>
            </posthog_single_shard>
            <posthog_migrations>
                <shard>
                    <replica>
                        <host>clickhouse</host>
                        <port>9000</port>
                    </replica>
                </shard>
            </posthog_migrations>
            <posthog_writable>
                <shard>
                    <replica>
                        <host>clickhouse</host>
                        <port>9000</port>
                    </replica>
                </shard>
            </posthog_writable>
            <posthog_primary_replica>
                <shard>
                    <replica>
                        <host>clickhouse</host>
                        <port>9000</port>
                    </replica>
                </shard>
            </posthog_primary_replica>

            <ai_events>
                <shard>
                    <replica>
                        <host>clickhouse</host>
                        <port>9000</port>
                    </replica>
                </shard>
            </ai_events>
            <aux>
                <shard>
                    <replica>
                        <host>clickhouse</host>
                        <port>9000</port>
                    </replica>
                </shard>
            </aux>
            <ops>
                <shard>
                    <replica>
                        <host>clickhouse</host>
                        <port>9000</port>
                    </replica>
                </shard>
            </ops>
            <sessions>
                <shard>
                    <replica>
                        <host>clickhouse</host>
                        <port>9000</port>
                    </replica>
                </shard>
            </sessions>
        </remote_servers>

        <named_collections>
            <msk_cluster>
                <kafka_broker_list from_env="KAFKA_HOSTS"/>
            </msk_cluster>
            <warpstream_ingestion>
                <kafka_broker_list from_env="KAFKA_HOSTS"/>
            </warpstream_ingestion>
            <warpstream_calculated_events>
                <kafka_broker_list from_env="KAFKA_HOSTS"/>
            </warpstream_calculated_events>
            <warpstream_replay>
                <kafka_broker_list from_env="KAFKA_HOSTS"/>
            </warpstream_replay>
            <warpstream_shared>
                <kafka_broker_list from_env="KAFKA_HOSTS"/>
            </warpstream_shared>
            <warpstream_cyclotron>
                <kafka_broker_list from_env="KAFKA_HOSTS"/>
            </warpstream_cyclotron>
            <warpstream_logs>
                <kafka_broker_list from_env="KAFKA_HOSTS"/>
            </warpstream_logs>
            <warpstream_traces>
                <kafka_broker_list from_env="KAFKA_HOSTS"/>
            </warpstream_traces>
        </named_collections>

        <macros>
            <shard>01</shard>
            <replica>ch1</replica>
            <hostClusterType>online</hostClusterType>
            <hostClusterRole>data</hostClusterRole>
        </macros>
    </clickhouse>
  XML

  # Source: PostHog docker/clickhouse/config.d/default.xml
  # Embedded keeper + zookeeper config for single-node ReplicatedMergeTree.
  # Update from: https://github.com/PostHog/posthog/blob/master/docker/clickhouse/config.d/default.xml
  posthog_keeper_xml = <<-XML
    <clickhouse>
      <keeper_server>
        <tcp_port>9182</tcp_port>
        <server_id>1</server_id>
        <log_storage_path>/var/lib/clickhouse/coordination/log</log_storage_path>
        <snapshot_storage_path>/var/lib/clickhouse/coordination/snapshots</snapshot_storage_path>
        <coordination_settings>
          <operation_timeout_ms>10000</operation_timeout_ms>
          <session_timeout_ms>30000</session_timeout_ms>
        </coordination_settings>
        <raft_configuration>
          <server><id>1</id><hostname>localhost</hostname><port>9234</port></server>
        </raft_configuration>
      </keeper_server>
      <zookeeper>
        <node><host>localhost</host><port>9182</port></node>
      </zookeeper>
    </clickhouse>
  XML

  # The Altinity operator's generated config.xml already defines all standard
  # system log tables (crash_log, metric_log, backup_log, etc.). We only add
  # what the operator does NOT provide: the merge_tree compat setting, the
  # session_log (commented out in the operator's config), and custom settings.
  #
  # Compat setting rationale: https://github.com/jdc-projects/clickhouse-compat
  posthog_compat_xml = <<-XML
    <clickhouse>
      <!-- Compat: restore 26.6 merge_tree validation behaviour -->
      <merge_tree>
        <allow_dimensions_outside_sorting_key>1</allow_dimensions_outside_sorting_key>
      </merge_tree>

      <!-- session_log is commented out in the operator's config.xml -->
      <session_log>
        <database>system</database>
        <table>session_log</table>
        <partition_by>toYYYYMM(event_date)</partition_by>
        <flush_interval_milliseconds>7500</flush_interval_milliseconds>
        <ttl>event_date + INTERVAL 5 DAY</ttl>
        <ttl_only_drop_parts>1</ttl_only_drop_parts>
      </session_log>

      <custom_settings_prefixes />
    </clickhouse>
  XML

  # Native ClickHouse Prometheus exporter endpoint.
  # https://clickhouse.com/docs/en/operations/monitoring
  # Modern ClickHouse (26.x) uses <endpoint> for the URL path and a separate
  # <port> for the listen port; the legacy host:port <endpoint> form is invalid.
  posthog_prometheus_xml = <<-XML
    <clickhouse>
      <prometheus>
        <endpoint>/metrics</endpoint>
        <port>9363</port>
        <metrics>true</metrics>
        <events>true</events>
        <asynchronous_metrics>true</asynchronous_metrics>
      </prometheus>
    </clickhouse>
  XML

  # Bounded retention for the ClickHouse system log tables that the operator's
  # default config.xml leaves without a TTL (text_log, query_views_log,
  # background_schedule_pool_log, metric_log, asynchronous_metric_log). The
  # other log tables (query_log, part_log, trace_log, processors_profile_log)
  # already carry a 30-day TTL via the operator's 01-clickhouse-*.xml files.
  # Without this, the system logs grow unbounded and fill the data volume.
  # text_log is additionally reduced from <level>trace</level> to information,
  # which is the main reason it reached ~10 GiB in two weeks.
  posthog_system_logs_xml = <<-XML
    <clickhouse>
      <text_log>
        <database>system</database>
        <table>text_log</table>
        <ttl>event_date + toIntervalDay(7)</ttl>
        <level>information</level>
      </text_log>
      <query_views_log>
        <database>system</database>
        <table>query_views_log</table>
        <ttl>event_date + toIntervalDay(7)</ttl>
      </query_views_log>
      <background_schedule_pool_log>
        <database>system</database>
        <table>background_schedule_pool_log</table>
        <ttl>event_date + toIntervalDay(7)</ttl>
      </background_schedule_pool_log>
      <metric_log>
        <database>system</database>
        <table>metric_log</table>
        <ttl>event_date + toIntervalDay(7)</ttl>
      </metric_log>
      <asynchronous_metric_log>
        <database>system</database>
        <table>asynchronous_metric_log</table>
        <ttl>event_date + toIntervalDay(7)</ttl>
      </asynchronous_metric_log>
    </clickhouse>
  XML
}

resource "kubernetes_manifest" "posthog_clickhouse" {
  manifest = {
    apiVersion = "clickhouse.altinity.com/v1"
    kind       = "ClickHouseInstallation"

    metadata = {
      name      = "posthog-ch"
      namespace = kubernetes_namespace.posthog.metadata[0].name
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
            name   = "posthog"
            layout = { shardsCount = 1, replicasCount = 1 }
          }
        ]

        files = {
          "posthog-clusters.xml"    = local.posthog_clusters_xml
          "posthog-keeper.xml"      = local.posthog_keeper_xml
          "posthog-compat.xml"      = local.posthog_compat_xml
          "posthog-system-logs.xml" = local.posthog_system_logs_xml
          "prometheus.xml"          = local.posthog_prometheus_xml
        }

        users = {
          default = {
            password          = ""
            networks          = { ip = "::/0" }
            access_management = 1
          }
          posthog = {
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
              hostAliases = [
                {
                  ip        = "127.0.0.1"
                  hostnames = ["clickhouse"]
                }
              ]
              containers = [
                {
                  name  = "clickhouse"
                  image = local.clickhouse_compat_image
                  env = [
                    { name = "KAFKA_HOSTS", value = "kafka:9092" }
                  ]
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
                requests = { storage = "50Gi" }
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
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  spec {
    selector = {
      "clickhouse.altinity.com/chi" = "posthog-ch"
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

  depends_on = [kubernetes_manifest.posthog_clickhouse]
}

resource "kubernetes_service" "clickhouse_metrics" {
  metadata {
    name      = "clickhouse-metrics"
    namespace = kubernetes_namespace.posthog.metadata[0].name

    labels = {
      "clickhouse.altinity.com/chi" = "posthog-ch"
    }
  }

  spec {
    selector = {
      "clickhouse.altinity.com/chi" = "posthog-ch"
    }

    port {
      name        = "metrics"
      port        = 9363
      target_port = 9363
    }
  }

  depends_on = [kubernetes_manifest.posthog_clickhouse]
}
