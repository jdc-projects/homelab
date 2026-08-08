# Event-driven test functions (Tier-1): each proves Serving + a Knative event
# source delivering CloudEvents to an event_display ksvc. Verified via the ksvc
# pod logs (kubectl logs) showing the received CloudEvents + the pod scaling
# 0->1 on event then back to 0 at idle. All ksvcs are cluster-local.

# --- fn-ticker: PingSource (built-in) -> ksvc --------------------------------

resource "kubernetes_manifest" "fn_ticker" {
  count = var.enable_tests.ticker ? 1 : 0

  manifest = {
    apiVersion = "serving.knative.dev/v1"
    kind       = "Service"

    metadata = {
      name      = "fn-ticker"
      namespace = local.test_ns

      labels = {
        "networking.knative.dev/visibility" = "cluster-local"
      }

      annotations = {
        "homelab.jdc/purpose" = "Tier-1: PingSource -> Serving (scale-to-zero + Traefik Knative provider)"
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

resource "kubernetes_manifest" "ping_fn_ticker" {
  count = var.enable_tests.ticker ? 1 : 0

  manifest = {
    apiVersion = "sources.knative.dev/v1"
    kind       = "PingSource"

    metadata = {
      name      = "ping-fn-ticker"
      namespace = local.test_ns
    }

    spec = {
      schedule    = "*/1 * * * *"
      contentType = "application/json"
      data        = "{\"message\":\"hello from ping-source\"}"

      sink = {
        ref = {
          apiVersion = "serving.knative.dev/v1"
          kind       = "Service"
          name       = "fn-ticker"
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.fn_ticker]
}

# --- fn-k8s: ApiServerSource -> ksvc (needs read perms on Pod/ConfigMap) ------

resource "kubernetes_manifest" "fn_k8s_reader_sa" {
  count = var.enable_tests.k8s ? 1 : 0

  manifest = {
    apiVersion = "v1"
    kind       = "ServiceAccount"

    metadata = {
      name      = "fn-k8s-reader"
      namespace = local.test_ns
    }
  }
}

resource "kubernetes_manifest" "fn_k8s_reader_role" {
  count = var.enable_tests.k8s ? 1 : 0

  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "Role"

    metadata = {
      name      = "fn-k8s-reader"
      namespace = local.test_ns
    }

    rules = [{
      apiGroups = [""]
      resources = ["pods", "configmaps"]
      verbs     = ["get", "list", "watch"]
    }]
  }
}

resource "kubernetes_manifest" "fn_k8s_reader_rolebinding" {
  count = var.enable_tests.k8s ? 1 : 0

  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "RoleBinding"

    metadata = {
      name      = "fn-k8s-reader"
      namespace = local.test_ns
    }

    subjects = [{
      kind      = "ServiceAccount"
      name      = "fn-k8s-reader"
      namespace = local.test_ns
    }]

    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "Role"
      name     = "fn-k8s-reader"
    }
  }

  depends_on = [kubernetes_manifest.fn_k8s_reader_role]
}

resource "kubernetes_manifest" "fn_k8s" {
  count = var.enable_tests.k8s ? 1 : 0

  manifest = {
    apiVersion = "serving.knative.dev/v1"
    kind       = "Service"

    metadata = {
      name      = "fn-k8s"
      namespace = local.test_ns

      labels = {
        "networking.knative.dev/visibility" = "cluster-local"
      }

      annotations = {
        "homelab.jdc/purpose" = "Tier-1: ApiServerSource (Pod/ConfigMap create) -> Serving"
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

resource "kubernetes_manifest" "k8s_fn_k8s" {
  count = var.enable_tests.k8s ? 1 : 0

  manifest = {
    apiVersion = "sources.knative.dev/v1"
    kind       = "ApiServerSource"

    metadata = {
      name      = "apiserver-fn-k8s"
      namespace = local.test_ns
    }

    spec = {
      resources = [
        { apiVersion = "v1", kind = "Pod" },
        { apiVersion = "v1", kind = "ConfigMap" }
      ]

      mode               = "Resource"
      serviceAccountName = "fn-k8s-reader"

      sink = {
        ref = {
          apiVersion = "serving.knative.dev/v1"
          kind       = "Service"
          name       = "fn-k8s"
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.fn_k8s, kubernetes_manifest.fn_k8s_reader_rolebinding]
}

# --- fn-kafka: KafkaSource -> ksvc -------------------------------------------

resource "kubernetes_manifest" "fn_kafka" {
  count = var.enable_tests.kafka ? 1 : 0

  manifest = {
    apiVersion = "serving.knative.dev/v1"
    kind       = "Service"

    metadata = {
      name      = "fn-kafka"
      namespace = local.test_ns

      labels = {
        "networking.knative.dev/visibility" = "cluster-local"
      }

      annotations = {
        "homelab.jdc/purpose" = "Tier-1: KafkaSource -> Serving (backed by in-module Strimzi Kafka)"
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

resource "kubernetes_manifest" "kafka_fn_kafka" {
  count = var.enable_tests.kafka ? 1 : 0

  manifest = {
    apiVersion = "sources.knative.dev/v1beta1"
    kind       = "KafkaSource"

    metadata = {
      name      = "kafka-fn-kafka"
      namespace = local.test_ns
    }

    spec = {
      bootstrapServers = ["kafka.${local.test_ns}.svc:9092"]
      topics           = [local.test_kafka_topic]
      consumerGroup    = "knative-test-fn-kafka"

      sink = {
        ref = {
          apiVersion = "serving.knative.dev/v1"
          kind       = "Service"
          name       = "fn-kafka"
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.fn_kafka, kubernetes_manifest.test_kafka_topic]
}

# --- fn-redis: RedisStreamSource (alpha) -> ksvc -----------------------------

resource "kubernetes_manifest" "fn_redis" {
  count = var.enable_tests.redis ? 1 : 0

  manifest = {
    apiVersion = "serving.knative.dev/v1"
    kind       = "Service"

    metadata = {
      name      = "fn-redis"
      namespace = local.test_ns

      labels = {
        "networking.knative.dev/visibility" = "cluster-local"
      }

      annotations = {
        "homelab.jdc/purpose"       = "Tier-1: RedisStreamSource (ALPHA) -> Serving (backed by in-module Valkey)"
        "homelab.jdc/alpha-feature" = "redis-stream-source"
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

resource "kubernetes_manifest" "redis_fn_redis" {
  count = var.enable_tests.redis ? 1 : 0

  manifest = {
    apiVersion = "sources.knative.dev/v1alpha1"
    kind       = "RedisStreamSource"

    metadata = {
      name      = "redis-fn-redis"
      namespace = local.test_ns
    }

    spec = {
      # The alpha adapter parses this as a URL, so it needs the redis:// scheme
      # (a bare host:port panics with "invalid URL scheme"). The CRD's
      # "TCP address" description is misleading.
      address = "redis://valkey.${local.test_ns}.svc:6379"
      stream  = "mystream"
      group   = "knative-test-fn-redis"

      sink = {
        ref = {
          apiVersion = "serving.knative.dev/v1"
          kind       = "Service"
          name       = "fn-redis"
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.fn_redis, helm_release.test_valkey]
}
