resource "kubernetes_cluster_role" "cdi_cloner" {
  metadata {
    name = "cdi-cloner"
  }

  rule {
    api_groups = [
      "cdi.kubevirt.io",
    ]
    resources = [
      "datavolumes/source",
    ]
    verbs = [
      "create",
    ]
  }
}
