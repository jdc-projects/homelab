output "serving_namespace" {
  value = kubernetes_namespace.knative_serving.metadata[0].name
}

output "eventing_namespace" {
  value = kubernetes_namespace.knative_eventing.metadata[0].name
}

# The ingress class app modules/functions must set on their KnativeService (or
# rely on as the cluster default): "traefik.ingress.networking.knative.dev".
output "serving_ingress_class" {
  value = local.ingress_class
}

# Which eventing source/broker capabilities are installed (read by app modules to
# decide which sources/brokers they can wire up without their own install).
output "eventing_sources_enabled" {
  value = {
    ping         = true  # built-in
    apiserver    = true  # built-in
    kafka        = true  # KafkaSource (source.kafka enabled)
    redis        = true  # RedisStreamSource (alpha; source.redis enabled)
    kafka_broker = false # Kafka Broker backend NOT installed: the operator's
    # source.kafka flag brings the Kafka SOURCE data plane only; the broker/
    # channel data plane (kafka-broker-dispatcher/receiver +
    # config-kafka-broker-data-plane) is not deployed. Use the default
    # channel-based Broker instead (what the live test in tests-broker.tf does).
  }
}
