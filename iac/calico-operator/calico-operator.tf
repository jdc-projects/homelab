# tigera-operator installed via the vendored upstream manifest (v3.32.1,
# projectcalico/calico). The manifest form is used instead of the Helm chart:
# the chart creates default Installation/Goldmane/Whisker instances in the same
# release as the CRDs those reference, racing CRD establishment under Helm and
# failing the install. This manifest only installs the Namespace + RBAC + the
# operator Deployment; the operator registers its own operator.tigera.io CRDs
# (Installation, etc.) at startup. The Installation CR is then applied separately
# by iac/calico, which waits for those CRDs to be Established.
#
# The operator pod is hostNetwork (verified in the manifest) and tolerates all
# taints, so it bootstraps on a CNI-less node: k3s runs with flannel disabled
# (see k3s/k3s.tf); the operator comes up, deploys calico-node (also hostNetwork)
# which installs the CNI plugin, and only then do normal pods get wired. This
# makes the install safe for fresh clusters and DR restores.
#
# kubectl apply is idempotent, so this re-runs safely whenever the manifest
# changes (triggered by its sha256).

resource "null_resource" "tigera_operator" {
  triggers = {
    manifest_sha = filesha256("${path.module}/tigera-operator.yaml")
  }

  provisioner "local-exec" {
    command = "kubectl --kubeconfig=${path.module}/../cluster.yml apply -f ${path.module}/tigera-operator.yaml"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl --kubeconfig=${path.module}/../cluster.yml delete -f ${path.module}/tigera-operator.yaml"
  }
}
