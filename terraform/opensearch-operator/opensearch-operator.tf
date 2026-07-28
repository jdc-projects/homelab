# https://github.com/opensearch-project/opensearch-k8s-operator

resource "helm_release" "opensearch_operator" {
  name      = "opensearch-operator"
  namespace = kubernetes_namespace.opensearch_operator.metadata[0].name

  repository = "https://opensearch-project.github.io/opensearch-k8s-operator/"
  chart      = "opensearch-operator"
  version    = "2.8.4"

  timeout = 300
}
