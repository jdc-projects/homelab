# Cross-namespace clone authorisation for Coder KubeVirt workspaces.
#
# Workspace templates clone golden VM images (kubernetes_persistent_volume_claim
# in kubevirt-images) into per-workspace DataVolumes in coder-workspaces. CDI
# requires the DataVolume creator to hold the `datavolumes/source` virtual
# permission on the source PVC in the source namespace — otherwise the clone
# stays Pending with "not authorized to clone".
#
# The creator is coderd's service account (coder/coder), which the coder helm
# chart grants VirtualMachine/DataVolume permissions in coder-workspaces via
# coder.serviceAccount.workspaceNamespaces[].extraRules (iac/coder/coder.tf).

resource "kubernetes_role" "coder_workspace_clone" {
  metadata {
    name      = "allow-clone-to-coder-workspaces"
    namespace = kubernetes_namespace.kubevirt_images.metadata[0].name
  }

  rule {
    api_groups     = ["cdi.kubevirt.io"]
    resources      = ["datavolumes/source"]
    resource_names = [kubernetes_persistent_volume_claim.opnsense["ubuntu-noble-server-cloudimg-amd64"].metadata[0].name]
    verbs          = ["*"]
  }
}

resource "kubernetes_role_binding" "coder_workspace_clone" {
  metadata {
    name      = "allow-clone-to-coder-workspaces"
    namespace = kubernetes_namespace.kubevirt_images.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.coder_workspace_clone.metadata[0].name
  }

  # virt-controller creates DataVolumes on behalf of VMs; CDI's clone
  # authorization checks them against the default ServiceAccount of the
  # DataVolume's namespace (coder-workspaces:default). The coder/coder SA is
  # also bound in case a template ever creates DataVolumes directly.
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "coder-workspaces"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "coder"
    namespace = "coder"
  }
}
