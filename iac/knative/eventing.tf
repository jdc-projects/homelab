# https://knative.dev/docs/install/operator/knative-with-operators/#installing-knative-eventing-with-event-sources
#
# Knative Eventing, reconciled by the Knative Operator. Built-in sources
# (PingSource, ApiServerSource) ship with Eventing. The Kafka and Redis source
# extensions are enabled explicitly:
#   - source.kafka: installs the Kafka eventing extension (KafkaSource data
#     plane only — NOT the Kafka broker/channel data plane; see README).
#   - source.redis: installs the (alpha) RedisStreamSource.
# The backing Kafka and Valkey instances live with the tests (tests-kafka.tf,
# tests-valkey.tf), reusing the already-installed Strimzi operator and the
# established valkey.io Helm chart.

resource "kubernetes_manifest" "knative_eventing" {
  manifest = {
    apiVersion = "operator.knative.dev/v1beta1"
    kind       = "KnativeEventing"

    metadata = {
      name      = "knative-eventing"
      namespace = kubernetes_namespace.knative_eventing.metadata[0].name
    }

    spec = {
      version = local.knative_version

      source = {
        # The Eventing CRD marks every source sub-object as required, so each
        # must be present (the unenabled ones explicitly disabled).
        ceph     = { enabled = false }
        github   = { enabled = false }
        gitlab   = { enabled = false }
        rabbitmq = { enabled = false }

        # Kafka eventing extension: KafkaSource data plane only (kafka-source-
        # dispatcher). The Kafka broker/channel data plane is NOT included.
        kafka = {
          enabled = true
        }

        # (Alpha) RedisStreamSource.
        redis = {
          enabled = true
        }
      }

      # The operator ships a broken tls-secret (placeholder PEM with no actual
      # cert body) that crashes the RedisStreamSource adapter — upstream bug
      # knative-extensions/eventing-redis#626. The controller's TLSSecretName()
      # falls back to "tls-secret" when the env var is empty (hardcoded default),
      # so we point it at a non-existent name instead. The Get() returns NotFound,
      # the controller skips loading the cert, r.tlsCert stays "", and the adapter
      # uses plain TCP (correct for in-cluster Valkey).
      workloads = [{
        name = "redis-controller-manager"
        env = [{
          container = "manager"
          envVars = [{
            name  = "SECRET_TLS_TLSCERTIFICATE"
            value = "none"
          }]
        }]
      }]
    }
  }

  computed_fields = [
    "metadata.labels",
    "metadata.annotations",
  ]
}
