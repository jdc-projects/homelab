# https://github.com/strimzi/strimzi-kafka-operator/tree/0.51.0/helm-charts/helm3/strimzi-kafka-operator

resource "helm_release" "kafka_operator" {
  name      = "strimzi-kafka-operator"
  namespace = kubernetes_namespace.kafka_operator.metadata[0].name

  repository = "https://strimzi.io/charts/"
  chart      = "strimzi-kafka-operator"
  version    = "0.51.0"

  timeout = 300

  set = [
    {
      name  = "watchAnyNamespace"
      value = "true"
    },
  ]
}
