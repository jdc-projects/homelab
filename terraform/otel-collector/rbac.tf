# RBAC for the k8sattributes processor: it enriches spans with Kubernetes
# metadata (namespace, pod, node, deployment) by querying the API server using
# the collector's own service account (`otel-collector`, created by the
# operator). The opentelemetry-operator does NOT auto-provision this in 0.156,
# so it is declared explicitly here. Bound cluster-wide because trace sources
# live across all namespaces.
resource "kubernetes_manifest" "otel_collector_k8sattributes_clusterrole" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRole"

    metadata = {
      name = "otel-collector-k8sattributes"
    }

    rules = [
      {
        apiGroups = [""]
        resources = ["pods", "namespaces", "nodes"]
        verbs     = ["get", "list", "watch"]
      },
      {
        apiGroups = ["apps"]
        resources = ["replicasets"]
        verbs     = ["get", "list", "watch"]
      },
    ]
  }
}

resource "kubernetes_manifest" "otel_collector_k8sattributes_binding" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"

    metadata = {
      name = "otel-collector-k8sattributes"
    }

    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "ClusterRole"
      name     = "otel-collector-k8sattributes"
    }

    subjects = [
      {
        kind      = "ServiceAccount"
        name      = "otel-collector"
        namespace = local.namespace
      },
    ]
  }

  depends_on = [kubernetes_manifest.otel_collector_k8sattributes_clusterrole]
}
