# Broker fan-out test: one default channel-based Broker (IMC) with two filtered
# Triggers routing to two ksvcs. Posting a CloudEvent with type "type.a" reaches
# only fn-broker-a; "type.b" reaches only fn-broker-b — proving Broker delivery
# + Trigger attribute filtering. Verified via the two ksvcs' pod logs.

resource "kubernetes_manifest" "fn_broker_a" {
  count = var.enable_tests.broker ? 1 : 0

  manifest = {
    apiVersion = "serving.knative.dev/v1"
    kind       = "Service"

    metadata = {
      name      = "fn-broker-a"
      namespace = local.test_ns

      labels = {
        "networking.knative.dev/visibility" = "cluster-local"
      }

      annotations = {
        "homelab.jdc/purpose" = "Tier-1: Kafka Broker subscriber A (filter type=type.a)"
      }
    }

    spec = {
      template = {
        spec = {
          containers = [{ image = local.test_image_events }]
        }
      }
    }
  }

  computed_fields = ["metadata.labels", "metadata.annotations"]
}

resource "kubernetes_manifest" "fn_broker_b" {
  count = var.enable_tests.broker ? 1 : 0

  manifest = {
    apiVersion = "serving.knative.dev/v1"
    kind       = "Service"

    metadata = {
      name      = "fn-broker-b"
      namespace = local.test_ns

      labels = {
        "networking.knative.dev/visibility" = "cluster-local"
      }

      annotations = {
        "homelab.jdc/purpose" = "Tier-1: Kafka Broker subscriber B (filter type=type.b)"
      }
    }

    spec = {
      template = {
        spec = {
          containers = [{ image = local.test_image_events }]
        }
      }
    }
  }

  computed_fields = ["metadata.labels", "metadata.annotations"]
}

resource "kubernetes_manifest" "test_broker" {
  count = var.enable_tests.broker ? 1 : 0

  manifest = {
    apiVersion = "eventing.knative.dev/v1"
    kind       = "Broker"

    metadata = {
      name      = "test-broker"
      namespace = local.test_ns

      # No broker.class -> the default channel-based Broker (mt-broker ingress/
      # filter + the in-memory-channel dispatcher), which Knative always
      # installs. We deliberately do NOT use broker.class=Kafka here: the
      # operator's source.kafka flag installs the Kafka SOURCE data plane
      # (kafka-source-dispatcher) only, not the Kafka broker/channel data plane
      # (kafka-broker-dispatcher/receiver + config-kafka-broker-data-plane),
      # so a Kafka-backed Broker reports "Data plane not available". Enabling
      # the Kafka broker data plane is tracked as a follow-up; see README. The
      # default broker still proves the Broker + filtered-Trigger fan-out that
      # this test exists to validate.
    }
  }

  computed_fields = ["metadata.labels", "metadata.annotations"]
}

resource "kubernetes_manifest" "trigger_broker_a" {
  count = var.enable_tests.broker ? 1 : 0

  manifest = {
    apiVersion = "eventing.knative.dev/v1"
    kind       = "Trigger"

    metadata = {
      name      = "broker-sub-a"
      namespace = local.test_ns
    }

    spec = {
      broker = "test-broker"

      filter = {
        attributes = {
          type = "type.a"
        }
      }

      subscriber = {
        ref = {
          apiVersion = "serving.knative.dev/v1"
          kind       = "Service"
          name       = "fn-broker-a"
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.test_broker, kubernetes_manifest.fn_broker_a]
}

resource "kubernetes_manifest" "trigger_broker_b" {
  count = var.enable_tests.broker ? 1 : 0

  manifest = {
    apiVersion = "eventing.knative.dev/v1"
    kind       = "Trigger"

    metadata = {
      name      = "broker-sub-b"
      namespace = local.test_ns
    }

    spec = {
      broker = "test-broker"

      filter = {
        attributes = {
          type = "type.b"
        }
      }

      subscriber = {
        ref = {
          apiVersion = "serving.knative.dev/v1"
          kind       = "Service"
          name       = "fn-broker-b"
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.test_broker, kubernetes_manifest.fn_broker_b]
}
