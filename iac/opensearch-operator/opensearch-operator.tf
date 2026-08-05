# https://github.com/opensearch-project/opensearch-k8s-operator

resource "helm_release" "opensearch_operator" {
  name      = "opensearch-operator"
  namespace = kubernetes_namespace.opensearch_operator.metadata[0].name

  repository = "https://opensearch-project.github.io/opensearch-k8s-operator/"
  chart      = "opensearch-operator"
  version    = "3.0.2"

  # v3.0.x exposes the manager's metrics bind address as a value (previously
  # hardcoded to 127.0.0.1:8080, which made /metrics unreachable from outside
  # the pod). Bind to 0.0.0.0 so the opensearch-operator-metrics Service can
  # route to it. v3 also drops kube-rbac-proxy; metrics auth is now handled by
  # controller-runtime (TokenReview + SubjectAccessReview), authorized via the
  # prometheus SA's existing get-on-/metrics ClusterRole.
  set = [
    {
      name  = "manager.metricsBindAddress"
      value = "0.0.0.0:8080"
    },
  ]

  timeout = 300
}
