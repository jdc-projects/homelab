# Read-only, cluster-scoped CRD schema access for coderd's embedded
# provisioners: the hashicorp/kubernetes provider inside workspace templates
# must look up CRD schemas for kubernetes_manifest resources (e.g. the
# KubeVirt VirtualMachine in iac/coder-template/templates/kubevirt). Without
# this, template imports fail with "failed to look up GVK ...
# customresourcedefinitions is forbidden". CRDs contain API schemas, not
# instance data.
resource "kubernetes_cluster_role" "coder_crd_reader" {
  metadata {
    name = "coder-crd-reader"
  }

  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "coder_crd_reader" {
  metadata {
    name = "coder-crd-reader"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.coder_crd_reader.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "coder"
    namespace = kubernetes_namespace.coder.metadata[0].name
  }
}
