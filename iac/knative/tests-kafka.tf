# Backing Kafka for fn-kafka (KafkaSource) and fn-broker-* (Kafka Broker), using
# the already-installed Strimzi operator (watchAnyNamespace=true, see
# iac/kafka-operator). Mirrors the proven posthog/sentry inline Kafka pattern: a
# single KRaft broker (controller+broker node pool) with a plain 9092 listener.
# No shared/central Kafka exists in the cluster, so each consumer brings its own
# (see iac/modules/README.md coupling notes).

locals {
  test_kafka_version = "4.1.0"
  test_kafka_topic   = "knative-test"
}

resource "kubernetes_manifest" "test_kafka" {
  count = anytrue([var.enable_tests.kafka, var.enable_tests.broker]) ? 1 : 0

  manifest = {
    apiVersion = "kafka.strimzi.io/v1beta2"
    kind       = "Kafka"

    metadata = {
      name      = "kafka"
      namespace = local.test_ns
    }

    spec = {
      kafka = {
        version = local.test_kafka_version

        listeners = [{
          name = "plain"
          port = 9092
          type = "internal"
          tls  = false
        }]

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

  computed_fields = ["metadata.labels", "metadata.annotations"]
}

resource "kubernetes_manifest" "test_kafka_node_pool" {
  count = anytrue([var.enable_tests.kafka, var.enable_tests.broker]) ? 1 : 0

  manifest = {
    apiVersion = "kafka.strimzi.io/v1beta2"
    kind       = "KafkaNodePool"

    metadata = {
      name      = "mixed"
      namespace = local.test_ns

      labels = {
        "strimzi.io/cluster" = "kafka"
      }
    }

    spec = {
      replicas = 1
      roles    = ["controller", "broker"]

      storage = {
        type        = "persistent-claim"
        size        = "5Gi"
        class       = "openebs-zfs-localpv-bulk"
        deleteClaim = false
      }

      resources = {
        requests = {
          cpu    = "250m"
          memory = "512Mi"
        }
        limits = {
          cpu    = "1500m"
          memory = "1Gi"
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.test_kafka]
}

# Topic consumed by fn-kafka's KafkaSource.
resource "kubernetes_manifest" "test_kafka_topic" {
  count = var.enable_tests.kafka ? 1 : 0

  manifest = {
    apiVersion = "kafka.strimzi.io/v1beta2"
    kind       = "KafkaTopic"

    metadata = {
      name      = local.test_kafka_topic
      namespace = local.test_ns

      labels = {
        "strimzi.io/cluster" = "kafka"
      }
    }

    spec = {
      partitions = 1
      replicas   = 1
    }
  }

  depends_on = [kubernetes_manifest.test_kafka_node_pool]
}

# Stable in-cluster bootstrap address for the KafkaSource (fn-kafka) to consume.
# (Strimzi creates kafka-bootstrap, but this mirrors the posthog/sentry pattern
# for a clean kafka.<ns>.svc:9092 reference.)
resource "kubernetes_service" "test_kafka" {
  count = anytrue([var.enable_tests.kafka, var.enable_tests.broker]) ? 1 : 0

  metadata {
    name      = "kafka"
    namespace = local.test_ns
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

  depends_on = [kubernetes_manifest.test_kafka]
}
