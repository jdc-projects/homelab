locals {
  # JMX Prometheus exporter rules for Strimzi Kafka brokers.
  # Source: https://github.com/strimzi/strimzi-kafka-operator/blob/main/examples/metrics/kafka-metrics.yaml
  kafka_jmx_metrics = <<-YAML
    lowercaseOutputName: true
    rules:
    - pattern: kafka.server<type=(.+), name=(.+), clientId=(.+), topic=(.+), partition=(.*)><>Value
      name: kafka_server_$1_$2
      type: GAUGE
      labels:
        clientId: "$3"
        topic: "$4"
        partition: "$5"
    - pattern: kafka.server<type=(.+), name=(.+), clientId=(.+), brokerHost=(.+), brokerPort=(.+)><>Value
      name: kafka_server_$1_$2
      type: GAUGE
      labels:
        clientId: "$3"
        broker: "$4:$5"
    - pattern: kafka.server<type=(.+), cipher=(.+), protocol=(.+), listener=(.+), networkProcessor=(.+)><>connections
      name: kafka_server_$1_connections_tls_info
      type: GAUGE
      labels:
        cipher: "$2"
        protocol: "$3"
        listener: "$4"
        networkProcessor: "$5"
    - pattern: kafka.server<type=(.+), clientSoftwareName=(.+), clientSoftwareVersion=(.+), listener=(.+), networkProcessor=(.+)><>connections
      name: kafka_server_$1_connections_software
      type: GAUGE
      labels:
        clientSoftwareName: "$2"
        clientSoftwareVersion: "$3"
        listener: "$4"
        networkProcessor: "$5"
    - pattern: "kafka.server<type=(.+), listener=(.+), networkProcessor=(.+)><>(.+-total):"
      name: kafka_server_$1_$4
      type: COUNTER
      labels:
        listener: "$2"
        networkProcessor: "$3"
    - pattern: "kafka.server<type=(.+), listener=(.+), networkProcessor=(.+)><>(.+):"
      name: kafka_server_$1_$4
      type: GAUGE
      labels:
        listener: "$2"
        networkProcessor: "$3"
    - pattern: kafka.server<type=(.+), listener=(.+), networkProcessor=(.+)><>(.+-total)
      name: kafka_server_$1_$4
      type: COUNTER
      labels:
        listener: "$2"
        networkProcessor: "$3"
    - pattern: kafka.server<type=(.+), listener=(.+), networkProcessor=(.+)><>(.+)
      name: kafka_server_$1_$4
      type: GAUGE
      labels:
        listener: "$2"
        networkProcessor: "$3"
    - pattern: kafka.(\w+)<type=(.+), name=(.+)Percent\w*><>MeanRate
      name: kafka_$1_$2_$3_percent
      type: GAUGE
    - pattern: kafka.(\w+)<type=(.+), name=(.+)Percent\w*><>Value
      name: kafka_$1_$2_$3_percent
      type: GAUGE
    - pattern: kafka.(\w+)<type=(.+), name=(.+)Percent\w*, (.+)=(.+)><>Value
      name: kafka_$1_$2_$3_percent
      type: GAUGE
      labels:
        "$4": "$5"
    - pattern: kafka.(\w+)<type=(.+), name=(.+)PerSec\w*, (.+)=(.+), (.+)=(.+)><>Count
      name: kafka_$1_$2_$3_total
      type: COUNTER
      labels:
        "$4": "$5"
        "$6": "$7"
    - pattern: kafka.(\w+)<type=(.+), name=(.+)PerSec\w*, (.+)=(.+)><>Count
      name: kafka_$1_$2_$3_total
      type: COUNTER
      labels:
        "$4": "$5"
    - pattern: kafka.(\w+)<type=(.+), name=(.+)PerSec\w*><>Count
      name: kafka_$1_$2_$3_total
      type: COUNTER
    - pattern: kafka.(\w+)<type=(.+), name=(.+), (.+)=(.+), (.+)=(.+)><>Value
      name: kafka_$1_$2_$3
      type: GAUGE
      labels:
        "$4": "$5"
        "$6": "$7"
    - pattern: kafka.(\w+)<type=(.+), name=(.+), (.+)=(.+)><>Value
      name: kafka_$1_$2_$3
      type: GAUGE
      labels:
        "$4": "$5"
    - pattern: kafka.(\w+)<type=(.+), name=(.+)><>Value
      name: kafka_$1_$2_$3
      type: GAUGE
    - pattern: kafka.(\w+)<type=(.+), name=(.+), (.+)=(.+), (.+)=(.+)><>Count
      name: kafka_$1_$2_$3_count
      type: COUNTER
      labels:
        "$4": "$5"
        "$6": "$7"
    - pattern: kafka.(\w+)<type=(.+), name=(.+), (.+)=(.*), (.+)=(.+)><>(\d+)thPercentile
      name: kafka_$1_$2_$3
      type: GAUGE
      labels:
        "$4": "$5"
        "$6": "$7"
        quantile: "0.$8"
    - pattern: kafka.(\w+)<type=(.+), name=(.+), (.+)=(.+)><>Count
      name: kafka_$1_$2_$3_count
      type: COUNTER
      labels:
        "$4": "$5"
    - pattern: kafka.(\w+)<type=(.+), name=(.+), (.+)=(.*)><>(\d+)thPercentile
      name: kafka_$1_$2_$3
      type: GAUGE
      labels:
        "$4": "$5"
        quantile: "0.$6"
    - pattern: kafka.(\w+)<type=(.+), name=(.+)><>Count
      name: kafka_$1_$2_$3_count
      type: COUNTER
    - pattern: kafka.(\w+)<type=(.+), name=(.+)><>(\d+)thPercentile
      name: kafka_$1_$2_$3
      type: GAUGE
      labels:
        quantile: "0.$4"
    - pattern: "kafka.server<type=raft-metrics><>(.+-total|.+-max):"
      name: kafka_server_raftmetrics_$1
      type: COUNTER
    - pattern: "kafka.server<type=raft-metrics><>(current-state): (.+)"
      name: kafka_server_raftmetrics_$1
      value: 1
      type: UNTYPED
      labels:
        $1: "$2"
    - pattern: "kafka.server<type=raft-metrics><>(.+):"
      name: kafka_server_raftmetrics_$1
      type: GAUGE
    - pattern: "kafka.server<type=raft-channel-metrics><>(.+-total|.+-max):"
      name: kafka_server_raftchannelmetrics_$1
      type: COUNTER
    - pattern: "kafka.server<type=raft-channel-metrics><>(.+):"
      name: kafka_server_raftchannelmetrics_$1
      type: GAUGE
    - pattern: "kafka.server<type=broker-metadata-metrics><>(.+):"
      name: kafka_server_brokermetadatametrics_$1
      type: GAUGE
  YAML
}

resource "kubernetes_config_map" "kafka_jmx_metrics" {
  metadata {
    name      = "sentry-kafka-jmx-metrics"
    namespace = local.ns
  }

  data = {
    "kafka-metrics.yml" = local.kafka_jmx_metrics
  }
}

resource "kubernetes_manifest" "kafka" {
  manifest = {
    apiVersion = "kafka.strimzi.io/v1beta2"
    kind       = "Kafka"

    metadata = {
      name      = "kafka"
      namespace = local.ns
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

        metricsConfig = {
          type = "jmxPrometheusExporter"

          valueFrom = {
            configMapKeyRef = {
              name = kubernetes_config_map.kafka_jmx_metrics.metadata[0].name
              key  = "kafka-metrics.yml"
            }
          }
        }
      }

      entityOperator = {
        topicOperator = {}
      }

      kafkaExporter = {}
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
      namespace = local.ns

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

# Topics are NOT pre-created here. The Sentry chart's externalKafka.provisioning
# Job (topicctl) creates them with replicationFactor=1 (single-broker cluster),
# and hooks.snubaInit.kafka.enabled is turned off in the release values to avoid
# duplicate creation.

resource "kubernetes_service" "kafka" {
  metadata {
    name      = "kafka"
    namespace = local.ns
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
