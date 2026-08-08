variable "server_base_domain" {
  type        = string
  description = "Base domain for the cluster. Knative Serving assigns public services the form <svc>.<namespace>.<domain>; cluster-local services resolve as <svc>.<namespace>.svc.cluster.local."
}

# Per-capability live-test toggles. All on by default so a fresh apply validates
# every enabled eventing source; flip to false to retire a test without ripping
# out the platform. Each is wired to a ksvc + its source in tests-*.tf.
variable "enable_tests" {
  type = object({
    ticker = bool # PingSource -> ksvc (Tier-1: Serving + Traefik provider + scale-to-zero)
    k8s    = bool # ApiServerSource -> ksvc
    kafka  = bool # KafkaSource -> ksvc (backed by an in-module Strimzi Kafka)
    redis  = bool # RedisStreamSource -> ksvc (backed by an in-module Valkey; source is alpha)
    broker = bool # Kafka Broker + two filtered Triggers -> two ksvcs (fan-out)
    public = bool # cluster-local ksvc exposed via the ingress module (Tier-2: auth + wildcard TLS)
  })

  default = {
    ticker = false
    k8s    = false
    kafka  = false
    redis  = false
    broker = false
    public = false
  }
}
