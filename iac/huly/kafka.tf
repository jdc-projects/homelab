# Strimzi Kafka - mirrors iac/posthog/kafka.tf, stripped to the essentials.
# Replaces Huly's bundled Redpanda. Huly's kafkajs client speaks the standard
# Kafka wire protocol (verified against source) so a real Kafka broker works
# drop-in. The 5 topics below are the ones Huly's `createTopics()` helper
# provisions (or relies on auto-create for) - declared here so the Strimzi
# Topic Operator owns them declaratively.
#
# Huly connects via the `kafka:9092` Service (plain PLAINTEXT listener, no
# SASL - matching what Huly's bundled Redpanda expected).

locals {
  kafka_topics = [
    "tx",
    "fulltext",
    "workspace",
    "users",
    "process",
  ]

  kafka_version = "4.1.0"
}

resource "kubernetes_manifest" "kafka" {
  manifest = {
    apiVersion = "kafka.strimzi.io/v1beta2"
    kind       = "Kafka"

    metadata = {
      name      = "kafka"
      namespace = kubernetes_namespace.huly.metadata[0].name
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
          "offsets.topic.replication.factor"         = "1"
          "transaction.state.log.replication.factor" = "1"
          "transaction.state.log.min.isr"            = "1"
          "default.replication.factor"               = "1"
          "min.insync.replicas"                      = "1"
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
      namespace = kubernetes_namespace.huly.metadata[0].name

      labels = {
        "strimzi.io/cluster" = "kafka"
      }
    }

    spec = {
      replicas = 1
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
          cpu    = "2000m"
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
      name      = each.key
      namespace = kubernetes_namespace.huly.metadata[0].name

      labels = {
        "strimzi.io/cluster" = "kafka"
      }
    }

    spec = {
      partitions = 1
      replicas   = 1
    }
  }

  depends_on = [kubernetes_manifest.kafka, kubernetes_manifest.kafka_node_pool]
}

# Fronts the Strimzi broker pods so Huly can resolve the bare `kafka:9092`
# name the chart's ConfigMap templates expect.
resource "kubernetes_service" "kafka" {
  metadata {
    name      = "kafka"
    namespace = kubernetes_namespace.huly.metadata[0].name
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
