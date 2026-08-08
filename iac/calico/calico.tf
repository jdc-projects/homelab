# The Calico Installation CR — tells the tigera-operator (installed by
# iac/calico-operator) how to deploy Calico. Split into its own module so it
# applies only after the operator.tigera.io CRDs are Established (the Helm
# release in the operator module creates the CRDs but doesn't guarantee they're
# Established mid-apply — same race that knative-operator -> knative avoids).

locals {
  # Kept on the existing k3s cluster-cidr so firewall/opnsense routes and the
  # address plan are unchanged. Calico's block IPAM (/26 blocks on demand)
  # removes the per-node /24 podCIDR ceiling that flannel was hitting.
  ippool_cidr = "10.42.0.0/16"
}

# Defensive: ensure the operator CRDs are Established before the Installation
# manifest applies. Harmless when they already are; guards a back-to-back local
# apply of both modules (the operator module runs in its own deploy job first).
resource "null_resource" "wait_for_operator_crds" {
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl --kubeconfig=${path.module}/../cluster.yml wait --for=condition=established --timeout=300s crd/installations.operator.tigera.io || true
    EOT
  }
}

resource "kubernetes_manifest" "installation" {
  manifest = {
    apiVersion = "operator.tigera.io/v1"
    kind       = "Installation"

    metadata = {
      name = "default"
    }

    spec = {
      calicoNetwork = {
        # VXLAN encapsulation = no BGP configuration.
        # natOutgoing preserves the previous flannel behaviour (pod egress SNATs
        # to the node IP). blockSize is left at the default /26, which
        # auto-scales per node.
        ipPools = [{
          cidr          = local.ippool_cidr
          encapsulation = "VXLAN"
          natOutgoing   = "Enabled"
        }]
      }
    }
  }

  computed_fields = ["metadata.annotations"]

  depends_on = [null_resource.wait_for_operator_crds]
}
