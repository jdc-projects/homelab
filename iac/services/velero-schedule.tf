data "terraform_remote_state" "velero" {
  backend = "kubernetes"

  config = {
    secret_suffix = "velero"
    config_path   = "../cluster.yml"
    namespace     = "tf-state"
  }
}

resource "kubernetes_config_map" "velero_resource_policy" {
  metadata {
    name      = "resource-policy"
    namespace = data.terraform_remote_state.velero.outputs.velero_namespace_name
  }

  data = {
    "resource-policy.yaml" = <<-EOF
      version: v1
      volumePolicies:
        - conditions:
            storageClass:
              - openebs-zfs-localpv-random-no-backup
              - openebs-zfs-localpv-general-no-backup
              - openebs-zfs-localpv-bulk-no-backup
          action:
            type: skip
        # - conditions:
        #     volumeTypes:
        #       - emptyDir
        #       - downwardAPI
        #       - projected
        #       - configMap
        #       - secret
        #   action:
        #     type: skip
    EOF
  }
}

resource "kubernetes_manifest" "velero_nightly_schedule" {
  manifest = {
    apiVersion = "velero.io/v1"
    kind       = "Schedule"

    metadata = {
      name      = data.terraform_remote_state.velero.outputs.nightly_backup_name
      namespace = data.terraform_remote_state.velero.outputs.velero_namespace_name
    }

    spec = {
      paused   = "true"
      schedule = "0 2 * * *"

      template = {
        csiSnapshotTimeout   = "23h"
        itemOperationTimeout = "23h"

        resourcePolicy = {
          kind = "configmap"
          name = kubernetes_config_map.velero_resource_policy.metadata[0].name
        }

        excludedNamespaces = [
          "default",
          "kube-system",
          "kube-public",
          "kube-node-lease",
          # CNI infra — re-provisioned by iac/calico on recovery, never restored.
          "calico-system",
          "tigera-operator",
        ]

        # Calico/Tigera cluster-scoped resources are owned by the tigera-operator
        # (iac/calico) and re-provisioned on recovery. Exclude them so a restore
        # onto a freshly-installed Calico doesn't try to recreate them over the
        # operator-managed ones.
        excludedResources = [
          "ippools.crd.projectcalico.org",
          "ipamblocks.crd.projectcalico.org",
          "ipamconfigs.crd.projectcalico.org",
          "ipamhandles.crd.projectcalico.org",
          "blockaffinities.crd.projectcalico.org",
          "felixconfigurations.crd.projectcalico.org",
          "clusterinformations.crd.projectcalico.org",
          "kubecontrollersconfigurations.crd.projectcalico.org",
          "bgpconfigurations.crd.projectcalico.org",
          "bgppeers.crd.projectcalico.org",
          "globalnetworkpolicies.crd.projectcalico.org",
          "globalnetworksets.crd.projectcalico.org",
          "networkpolicies.crd.projectcalico.org",
          "networksets.crd.projectcalico.org",
          "hostendpoints.crd.projectcalico.org",
          "installations.operator.tigera.io",
          "tigerastatuses.operator.tigera.io",
          "apiservers.operator.tigera.io",
          "imagesets.operator.tigera.io",
        ]

        includeClusterResources = true
      }
    }
  }
}