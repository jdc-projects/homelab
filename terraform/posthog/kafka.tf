locals {
  kafka_topics = [
    "clickhouse_events_json",
    "clickhouse_ai_events_json",
    "clickhouse_heatmap_events",
    "clickhouse_ingestion_warnings",
    "events_plugin_ingestion",
    "events_plugin_ingestion_historical",
    "events_plugin_ingestion_dlq",
    "events_plugin_ingestion_overflow",
    "events_plugin_ingestion_async",
    "ingestion-clientwarnings-main-1",
    "heatmaps_ingestion",
    "clickhouse_groups",
    "clickhouse_person",
    "clickhouse_person_distinct_id",
    "clickhouse_app_metrics2",
    "log_entries",
    "clickhouse_tophog",
    "session_recording_snapshot_item_events",
    "ai_events_ingestion",
    "logs_ingestion",
    "metrics_ingestion",
    "ingestion-errortracking-main",
  ]

  livestream_config = <<-YAML
    debug: false
    kafka:
        brokers: 'kafka:9092'
        topic: 'events_plugin_ingestion'
        group_id: 'livestream'
        security_protocol: 'PLAINTEXT'
        session_recording_enabled: true
        session_recording_security_protocol: 'PLAINTEXT'
    consumers:
        event:
            enabled: true
            brokers: 'kafka:9092'
            topic: 'events_plugin_ingestion'
            security_protocol: 'PLAINTEXT'
            group_id: 'livestream'
        session_recording:
            enabled: true
            brokers: 'kafka:9092'
            topic: 'session_recording_snapshot_item_events'
            security_protocol: 'PLAINTEXT'
            group_id: 'livestream-session-recordings'
        notification:
            enabled: false
    mmdb:
        path: '/share/GeoLite2-City.mmdb'
  YAML
}

resource "kubernetes_manifest" "kafka" {
  manifest = {
    apiVersion = "kafka.strimzi.io/v1beta2"
    kind       = "Kafka"

    metadata = {
      name      = "kafka"
      namespace = kubernetes_namespace.posthog.metadata[0].name
    }

    spec = {
      kafka = {
        version = local.kafka_version

        listeners = [
          {
            name = "plain"
            port = 9092
            type = "internal"
            tls  = false
          }
        ]

        config = {
          "offsets.topic.replication.factor"         = "3"
          "transaction.state.log.replication.factor" = "3"
          "transaction.state.log.min.isr"            = "2"
          "default.replication.factor"               = "3"
          "min.insync.replicas"                      = "2"
        }
      }

      entityOperator = {
        topicOperator = {}
      }
    }
  }

  computed_fields = [
    "metadata.labels",
    "metadata.annotations",
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_manifest" "kafka_node_pool" {
  manifest = {
    apiVersion = "kafka.strimzi.io/v1beta2"
    kind       = "KafkaNodePool"

    metadata = {
      name      = "mixed"
      namespace = kubernetes_namespace.posthog.metadata[0].name

      labels = {
        "strimzi.io/cluster" = "kafka"
      }
    }

    spec = {
      replicas = 3
      roles    = ["controller", "broker"]

      storage = {
        type        = "persistent-claim"
        size        = "10Gi"
        class       = "openebs-zfs-localpv-bulk"
        deleteClaim = false
      }

      resources = {
        requests = {
          cpu    = "250m"
          memory = "512Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "1Gi"
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.kafka]
}

resource "kubernetes_manifest" "kafka_topics" {
  for_each = toset(local.kafka_topics)

  manifest = {
    apiVersion = "kafka.strimzi.io/v1beta2"
    kind       = "KafkaTopic"

    metadata = {
      name      = replace(each.key, "_", "-")
      namespace = kubernetes_namespace.posthog.metadata[0].name

      labels = {
        "strimzi.io/cluster" = "kafka"
      }
    }

    spec = {
      partitions = 1
      replicas   = 3
      topicName  = each.key
    }
  }

  depends_on = [kubernetes_manifest.kafka, kubernetes_manifest.kafka_node_pool]
}

resource "kubernetes_config_map" "livestream_config" {
  metadata {
    name      = "livestream-config"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    "configs.yml" = local.livestream_config
  }
}

resource "kubernetes_service" "kafka" {
  metadata {
    name      = "kafka"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  spec {
    port {
      port = 9092
    }

    selector = {
      "strimzi.io/cluster" = "kafka"
      "strimzi.io/name"    = "kafka-kafka"
    }
  }

  depends_on = [kubernetes_manifest.kafka]
}
