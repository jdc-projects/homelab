# Knative (Serving + Eventing)

Installs Knative via the [Knative Operator](../knative-operator/) and ships a set
of **live test functions** (in `knative-test`) that prove every enabled eventing
capability, plus a **pattern catalog** (below) for adding real functions inside
app modules.

## What this module installs

| Resource | File | Notes |
|---|---|---|
| `KnativeServing` | `serving.tf` | core Serving; ingress class `traefik.ingress.networking.knative.dev` (Istio plugin disabled — Traefik is the external ingress); request traces → OTel collector; `autocreate-cluster-domain-claims` enabled |
| `KnativeEventing` | `eventing.tf` | core Eventing + `source.kafka` (KafkaSource data plane only) + `source.redis` (RedisStreamSource, **alpha**) |
| Live test fns | `tests-*.tf` | one per capability, all togglable via `var.enable_tests` |

> **Kafka broker data plane is NOT installed.** The operator's `source.kafka`
> flag deploys the Kafka **source** data plane (`kafka-source-dispatcher`) only.
> The Kafka **broker/channel** data plane (`kafka-broker-dispatcher`/`receiver` +
> `config-kafka-broker-data-plane`) is absent. Use the **default channel-based
> Broker** (mt-broker + IMC) — which is what `tests-broker.tf` does.

Outputs app modules consume via `terraform_remote_state.knative`: serving
namespace, eventing namespace, ingress class, and which sources are installed.

## Two-tier routing (important)

Functions are routed one of two ways:

### Tier-1 — Traefik Knative provider (cluster-local / internal functions)

Enabled in `iac/traefik` (`experimental.knative` + `providers.knative.enabled`).
Knative stamps an internal `Ingress` (Kingress); the Traefik provider reconciles
it into Traefik routes. Reach cluster-local functions in-cluster at
`http://<svc>.<ns>.svc.cluster.local`.

**Three things the Traefik chart doesn't expose in its values schema** — they're
passed as CLI flags in `iac/traefik/traefik.tf`:

1. **`privateEntrypoints`** — a dedicated plain-HTTP entrypoint (`knative`,
   port 8080) without the `web`→`websecure` redirect. The provider **silently
   skips ALL cluster-local Kingress rules** if this is nil (a hard guard in
   `buildRouters()`). This was the root cause of the provider producing zero
   routes before the fix.
2. **`privateService`** — the `traefik-internal` ClusterIP Service (see below).
   The provider writes this into each Kingress's `status.loadBalancer`; Serving
   reads it to create the ksvc's ExternalName Service (the DNS alias that
   in-cluster callers resolve).
3. The **`traefik-internal` ClusterIP Service** — selects the hostNetwork
   DaemonSet pods on port 8080. Without it, the Kingress status is empty and
   Serving's ExternalName target points nowhere.

The provider is **experimental**; keep blast-radius small by not exposing
internet-facing functions through it.

### Tier-2 — shared `ingress` module (internet-facing functions)

Make the ksvc `cluster-local` (so Tier-1 handles internal routing) and expose it
through the shared `ingress` module (TLS via wildcard cert, shared middleware
chain: cloudflare/geoblock/crowdsec, auth).

**The Tier-2 IngressRoute cannot point at the ksvc's own Service** — it's an
ExternalName → `traefik-internal` (the Tier-1 gateway). That creates a hairpin
(Tier-2 → ExternalName → traefik-internal → knative entrypoint) where the
external Host header (`my-fn.jd-chapman.dev`) doesn't match any knative
entrypoint route (which only knows cluster-local hostnames). A Knative
`DomainMapping` doesn't help either — the provider has a `// TODO: support
rewrite host` and rejects ExternalName backends (no ClusterIP).

**Solution:** create a small ClusterIP Service that selects the ksvc's revision
pods directly, and point the ingress module at it. This bypasses the Kingress
entirely for the Tier-2 path. The trade-off is no scale-to-zero wake-up via this
path (the Service has no endpoints when the revision is at zero); either pin
`min-scale=1` or accept cold-start 503s for internet-facing functions.

## Live test functions (`knative-test`)

Each is gated by a flag in `var.enable_tests` (all on by default). Verify with
the commands in the [verification checklist](#verification-checklist).

| Test | Proves | Backing service |
|---|---|---|
| `fn-ticker` | PingSource → Serving + scale-to-zero + Traefik Knative provider | — |
| `fn-k8s` | ApiServerSource (Pod/ConfigMap) → Serving | — (own SA+Role) |
| `fn-kafka` | KafkaSource → Serving | in-module Strimzi Kafka (`tests-kafka.tf`) |
| `fn-redis` | RedisStreamSource (**alpha**) → Serving | in-module Valkey (`tests-valkey.tf`) |
| `fn-broker-a/b` | default channel-based Broker + two filtered Triggers (fan-out) | — (IMC, not Kafka) |
| `fn-public` | Tier-2 public routing + wildcard TLS + middleware chain | — |

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

Make the ksvc cluster-local, create a **direct Service** that selects revision
pods (the Tier-2 path can't use the ksvc's ExternalName Service — see
[Two-tier routing](#tier-2--shared-ingress-module-internet-facing-functions)
above), then expose it through the shared ingress module:

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
    spec = {
      template = {
        metadata = {
          annotations = {
            "autoscaling.knative.dev/min-scale" = "1"   # no scale-to-zero via Tier-2 path
          }
        }
        spec = { containers = [{ image = "..." }] }
      }
    }
  }
  computed_fields = ["metadata.labels", "metadata.annotations"]
}

# Direct ClusterIP Service selecting revision pods (port 80 -> queue-proxy 8012).
# The ingress module points here, NOT at the ksvc's ExternalName Service.
resource "kubernetes_service" "my_public_fn_direct" {
  metadata {
    name      = "my-public-fn-direct"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  spec {
    selector = { "serving.knative.dev/service" = "my-public-fn" }
    port {
      name        = "http"
      port        = 80
      target_port = 8012
    }
  }
  depends_on = [kubernetes_manifest.my_public_fn]
}

module "my_public_fn_ingress" {
  source  = "../modules/ingress"
  name    = "my-public-fn"
  domain  = "my-fn.${var.server_base_domain}"
  namespace = kubernetes_namespace.app.metadata[0].name

  existing_service_name      = kubernetes_service.my_public_fn_direct.metadata[0].name
  existing_service_namespace = kubernetes_namespace.app.metadata[0].name
  target_port                = 80

  auth_mode           = "oidc-interactive"              # or oidc-api / api-key / none
  keycloak_auth_realm = "primary"
}
```

### KafkaSource → function

```hcl
resource "kubernetes_manifest" "my_kafka_source" {
  manifest = {
    apiVersion = "sources.knative.dev/v1beta1"
    kind       = "KafkaSource"
    metadata = { name = "my-kafka-source", namespace = kubernetes_namespace.app.metadata[0].name }
    spec = {
      bootstrapServers = ["kafka.<ns>.svc:9092"]   # your Strimzi Kafka
      topics           = ["my-app-events"]
      consumerGroup    = "my-app-fn"
      sink = { ref = { apiVersion = "serving.knative.dev/v1", kind = "Service", name = "my-fn" } }
    }
  }
}
```

### RedisStreamSource → function (alpha)

> **Two alpha-source quirks** (both handled by this module):
> 1. The `address` field **must** use the `redis://` URL scheme — the adapter
>    panics with `"redis: invalid URL scheme"` on a bare `host:port`.
> 2. The operator ships a broken `tls-secret` (placeholder PEM with no cert
>    body) that crashes the adapter (`panic called with nil argument`) —
>    upstream bug
>    [knative-extensions/eventing-redis#626](https://github.com/knative-extensions/eventing-redis/issues/626),
>    closed stale/unfixed. This module overrides the controller's
>    `SECRET_TLS_TLSCERTIFICATE` env var to empty via `spec.workloads` on the
>    KnativeEventing CR, so it never reads the broken Secret and the adapter
>    uses plain TCP.

```hcl
resource "kubernetes_manifest" "my_redis_source" {
  manifest = {
    apiVersion = "sources.knative.dev/v1alpha1"
    kind       = "RedisStreamSource"
    metadata = { name = "my-redis-source", namespace = kubernetes_namespace.app.metadata[0].name }
    spec = {
      address = "redis://valkey.<ns>.svc:6379"   # MUST include redis:// scheme
      stream  = "mystream"
      group   = "my-app-fn"
      sink = { ref = { apiVersion = "serving.knative.dev/v1", kind = "Service", name = "my-fn" } }
    }
  }
}
```

### Broker + filtered Triggers (fan-out)

Uses the **default channel-based Broker** (mt-broker ingress/filter + in-memory
channel dispatcher). No `broker.class` annotation needed — the Kafka broker
backend is not installed (see note above).

```hcl
resource "kubernetes_manifest" "broker" {
  manifest = {
    apiVersion = "eventing.knative.dev/v1"
    kind       = "Broker"
    metadata = {
      name      = "my-broker"
      namespace = kubernetes_namespace.app.metadata[0].name
      # No broker.class annotation -> default channel-based Broker (IMC).
      # The broker's address will be:
      #   http://broker-ingress.knative-eventing.svc.cluster.local/<ns>/my-broker
    }
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
      subscriber = {
        ref = { apiVersion = "serving.knative.dev/v1", kind = "Service", name = "my-fn" }
      }
    }
  }
}
```

> The broker's sink URL is `broker-ingress.knative-eventing.svc.cluster.local`
> with the path `/<namespace>/<broker-name>`, NOT `<broker-name>.<ns>.svc`.
> Check with `kubectl -n <ns> get broker <name> -o jsonpath='{.status.address.url}'`.

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

Run after deploy:

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
kubectl -n knative-test exec svc/valkey -- redis-cli XADD mystream '*' task ping
kubectl -n knative-test logs -l serving.knative.dev/service=fn-redis --tail=20

# Broker fan-out — post one event of each type, watch each ksvc get its filtered subset:
kubectl -n knative-test run curl --rm -i --restart=Never --image=curlimages/curl -- \
  curl -s -X POST \
  http://broker-ingress.knative-eventing.svc.cluster.local/knative-test/test-broker \
  -H "Ce-Id: 1" -H "Ce-Specversion: 1.0" -H "Ce-Type: type.a" \
  -H "Content-Type: application/json" -d '{"x":1}'
kubectl -n knative-test logs -l serving.knative.dev/service=fn-broker-a --tail=10  # gets type.a
kubectl -n knative-test logs -l serving.knative.dev/service=fn-broker-b --tail=10  # does NOT get type.a

# Tier-2 public fn (TLS + shared middleware chain) — 405 = function reached (event_display rejects GET)
curl -sI https://fn-public.<server_base_domain>     # expect 405 (or 200 if your fn handles GET)
```

## Tearing down the tests

Set the relevant `var.enable_tests.*` to `false` (or all of them) and re-apply.
The `knative-test` namespace is removed automatically when no test is enabled.
The platform install (Serving/Eventing) stays.
