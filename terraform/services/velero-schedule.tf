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
        ]

        includeClusterResources = true
      }
    }
  }
}