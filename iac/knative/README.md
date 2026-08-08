# Knative (Serving + Eventing)

Installs Knative via the [Knative Operator](../knative-operator/) and ships a set
of **live test functions** (in `knative-test`) that prove every enabled eventing
capability, plus a **pattern catalog** (below) for adding real functions inside
app modules.

## What this module installs

| Resource | File | Notes |
|---|---|---|
| `KnativeServing` | `serving.tf` | core Serving; ingress class `traefik.ingress.networking.knative.dev` (Istio plugin disabled — Traefik is the external ingress); request traces → OTel collector |
| `KnativeEventing` | `eventing.tf` | core Eventing + `source.kafka` (KafkaSource + Kafka Broker/Channel/Sink) + `source.redis` (RedisStreamSource, **alpha**) |
| ServiceMonitors | `observability.tf` | serving + eventing control-plane metrics (auto-scraped by the select-all Prometheus) |
| Live test fns | `tests-*.tf` | one per capability, all togglable via `var.enable_tests` |

Outputs app modules consume via `terraform_remote_state.knative`: serving
namespace, ingress class, Kafka broker class, and which sources are installed.

## Two-tier routing (important)

Functions are routed one of two ways:

- **Tier-1 — Knative's own ingress via the Traefik Knative provider.** Enabled in
  `iac/traefik` (`experimental.knative` + `providers.knative.enabled`). Knative
  stamps an internal `Ingress`; Traefik reconciles it. Use this for
  **cluster-local / internal** functions (event sinks, internal APIs). Reach them
  in-cluster at `http://<svc>.<ns>.svc.cluster.local`. The Traefik Knative
  provider is **experimental**; keep blast-radius small by not exposing
  internet-facing functions through it.
- **Tier-2 — the shared `ingress` module pointing at the ksvc's Service.** Use
  this for **internet-facing** functions. Make the ksvc `cluster-local` (so
  Knative does NOT also publish it via Tier-1) and let the ingress module own TLS
  (wildcard cert), the shared middleware chain (cloudflare/geoblock/crowdsec),
  and auth (oidc-interactive / oidc-api / api-key). Knative `DomainMapping` is
  avoided (broken with the Traefik provider) by using an IngressRoute instead.

## Live test functions (`knative-test`)

Each is gated by a flag in `var.enable_tests` (all on by default). Verify with
the commands in the [verification checklist](#verification-checklist).

| Test | Proves | Backing service |
|---|---|---|
| `fn-ticker` | PingSource → Serving + scale-to-zero + Traefik Knative provider | — |
| `fn-k8s` | ApiServerSource (Pod/ConfigMap) → Serving | — (own SA+Role) |
| `fn-kafka` | KafkaSource → Serving | in-module Strimzi Kafka (`tests-kafka.tf`) |
| `fn-redis` | RedisStreamSource (**alpha**) → Serving | in-module Valkey (`tests-valkey.tf`) |
| `fn-broker-a/b` | Kafka Broker + two filtered Triggers (fan-out) | the in-module Kafka |
| `fn-public` | Tier-2 public routing + wildcard TLS + middleware chain (auth via ingress module) | — |

There is **no shared/central Kafka or Valkey** in the cluster, so the Kafka/Redis
tests bring their own (Strimzi `Kafka` CR + `valkey` Helm release), mirroring
`iac/posthog/kafka.tf` and `iac/n8n/valkey.tf`.

## Pattern catalog (for app modules)

Consume the platform from an app module (e.g. `iac/<app>/`) with remote state,
then add a `kubernetes_manifest` per function. Sinks use
`gcr.io/knative-releases/knative.dev/eventing/cmd/event_display` here only because
it logs CloudEvents; real functions use your own image.

```hcl
data "terraform_remote_state" "knative" {
  backend = "kubernetes"
  config = {
    secret_suffix = "knative"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}
```

### Tier-1: event-driven function (PingSource / ApiServerSource)

```hcl
resource "kubernetes_manifest" "my_fn" {
  manifest = {
    apiVersion = "serving.knative.dev/v1"
    kind       = "Service"
    metadata = {
      name      = "my-fn"
      namespace = kubernetes_namespace.app.metadata[0].name
      labels    = { "networking.knative.dev/visibility" = "cluster-local" } # internal
    }
    spec = {
      template = {
        spec = { containers = [{ image = "ghcr.io/you/my-fn:v1.2.3@sha256:..." }] }
      }
    }
  }
  computed_fields = ["metadata.labels", "metadata.annotations"]
}

resource "kubernetes_manifest" "my_fn_ping" {
  manifest = {
    apiVersion = "sources.knative.dev/v1"
    kind       = "PingSource"
    metadata = { name = "my-fn-ping", namespace = kubernetes_namespace.app.metadata[0].name }
    spec = {
      schedule    = "*/5 * * * *"
      contentType = "application/json"
      data        = jsonencode({ task = "reconcile" })
      sink = { ref = { apiVersion = "serving.knative.dev/v1", kind = "Service", name = "my-fn" } }
    }
  }
  depends_on = [kubernetes_manifest.my_fn]
}
```

ApiServerSource needs its own `ServiceAccount` + `Role` (get/list/watch) — see
`tests-sources.tf` (`fn_k8s_reader_*`).

### Tier-2: public + authenticated function (the canonical internet pattern)

Make the ksvc cluster-local, then expose it through the shared ingress module
(this is exactly `fn-public`):

```hcl
resource "kubernetes_manifest" "my_public_fn" {
  manifest = {
    apiVersion = "serving.knative.dev/v1"
    kind       = "Service"
    metadata = {
      name      = "my-public-fn"
      namespace = kubernetes_namespace.app.metadata[0].name
      labels    = { "networking.knative.dev/visibility" = "cluster-local" } # Tier-2 owns exposure
    }
    spec = { template = { spec = { containers = [{ image = "..." }] } } }
  }
  computed_fields = ["metadata.labels", "metadata.annotations"]
}

module "my_public_fn_ingress" {
  source  = "../modules/ingress"
  name    = "my-public-fn"
  domain  = "my-fn.${var.server_base_domain}"
  namespace = kubernetes_namespace.app.metadata[0].name

  existing_service_name      = "my-public-fn"          # the ksvc's Service
  existing_service_namespace = kubernetes_namespace.app.metadata[0].name
  target_port                = 80                       # ksvc serves on :80

  auth_mode           = "oidc-interactive"              # or oidc-api / api-key / none
  keycloak_auth_realm = "primary"
}
```

### KafkaSource → function

```hcl
spec = {
  bootstrapServers = ["kafka.<ns>.svc:9092"]   # your Strimzi Kafka
  topics           = ["my-app-events"]
  consumerGroup    = "my-app-fn"
  sink = { ref = { apiVersion = "serving.knative.dev/v1", kind = "Service", name = "my-fn" } }
}
# apiVersion: sources.knative.dev/v1beta1 ; kind: KafkaSource
```

### RedisStreamSource → function (alpha)

```hcl
spec = {
  address = "valkey.<ns>.svc:6379"   # host:port (NOT redis://)
  stream  = "mystream"
  group   = "my-app-fn"
  sink = { ref = { apiVersion = "serving.knative.dev/v1", kind = "Service", name = "my-fn" } }
}
# apiVersion: sources.knative.dev/v1alpha1 ; kind: RedisStreamSource
```

### Kafka Broker + filtered Triggers (fan-out)

```hcl
# config ConfigMap carrying bootstrap.servers -> see tests-kafka.tf (kafka_broker_config)
resource "kubernetes_manifest" "broker" {
  manifest = {
    apiVersion = "eventing.knative.dev/v1"
    kind       = "Broker"
    metadata = {
      name      = "my-broker"
      namespace = kubernetes_namespace.app.metadata[0].name
      annotations = { "eventing.knative.dev/broker.class" = data.terraform_remote_state.knative.outputs.kafka_broker_class }
    }
    spec = { config = { apiVersion = "v1", kind = "ConfigMap", name = "my-broker-config", namespace = kubernetes_namespace.app.metadata[0].name } }
  }
}

resource "kubernetes_manifest" "trigger" {
  manifest = {
    apiVersion = "eventing.knative.dev/v1"
    kind       = "Trigger"
    metadata = { name = "my-fn-trigger", namespace = kubernetes_namespace.app.metadata[0].name }
    spec = {
      broker = "my-broker"
      filter = { attributes = { type = "my-app.event.thing-happened" } }
      subscriber = { ref = { apiVersion = "serving.knative.dev/v1", kind = "Service", name = "my-fn" } }
    }
  }
}
```

### Knative Service knobs (autoscaling / traffic-splitting)

```hcl
spec = {
  template = {
    metadata = {
      annotations = {
        "autoscaling.knative.dev/class"                = "kpa.autoscaling.knative.dev" # default
        "autoscaling.knative.dev/min-scale"            = "0"   # allow scale-to-zero
        "autoscaling.knative.dev/max-scale"            = "10"
        "autoscaling.knative.dev/target"               = "100" # concurrent requests per pod
        "autoscaling.knative.dev/scale-to-zero-pod-retention-period" = "30s"
      }
    }
    spec = { containers = [{ image = "...", env = [{ name = "PORT", value = "8080" }] }] }
  }
  # Blue/green: split traffic across revisions
  traffic = [
    { tag = "current", revisionName = "my-fn-00001", percent = 90 },
    { tag = "candidate", revisionName = "my-fn-00002", percent = 10 },
  ]
}
```

## Verification checklist

Run after deploy (and after the node's pod CIDR is `/20` — see `k3s/README.md`):

```sh
# Serving + Tier-1 (Traefik Knative provider) + scale-to-zero
kubectl -n knative-test get ksvc fn-ticker
kubectl -n knative-test logs -l serving.knative.dev/service=fn-ticker --tail=20   # CloudEvents from PingSource
# cold start: watch pods scale 0->1 on an event, then ->0 at idle:
kubectl -n knative-test get pods -l serving.knative.dev/service=fn-ticker -w

# ApiServerSource
kubectl -n knative-test logs -l serving.knative.dev/service=fn-k8s --tail=20

# KafkaSource — seed a message, then read the ksvc logs:
kubectl -n knative-test exec kafka-kafka-0 -- bin/kafka-console-producer.sh \
  --bootstrap-server localhost:9092 --topic knative-test <<< '{"hello":"kafka"}'
kubectl -n knative-test logs -l serving.knative.dev/service=fn-kafka --tail=20

# RedisStreamSource (alpha) — seed stream entries, then read logs:
kubectl -n knative-test exec svc/valkey -- redis-cli XADD mystream '* task ping'
kubectl -n knative-test logs -l serving.knative.dev/service=fn-redis --tail=20

# Kafka Broker fan-out — post one event of each type, watch each ksvc get its filtered subset:
BROKER_URL=$(kubectl -n knative-test get broker kafka-broker -o jsonpath='{.status.address.url}')
kubectl -n knative-test run curl --rm -i --restart=Never --image=curlimages/curl -- \
  curl -s -X POST "$BROKER_URL" -H "Ce-Id: 1" -H "Ce-Specversion: 1.0" \
  -H "Ce-Type: type.a" -H "Content-Type: application/json" -d '{"x":1}'
kubectl -n knative-test logs -l serving.knative.dev/service=fn-broker-a --tail=10
kubectl -n knative-test logs -l serving.knative.dev/service=fn-broker-b --tail=10

# Tier-2 public fn (TLS + shared middleware chain)
curl -sI https://fn-public.<server_base_domain>     # 200 (auth_mode=none here)
```

## Tearing down the tests

Set the relevant `var.enable_tests.*` to `false` (or all of them) and re-apply.
The `knative-test` namespace is removed automatically when no test is enabled.
The platform install (Serving/Eventing) stays.
