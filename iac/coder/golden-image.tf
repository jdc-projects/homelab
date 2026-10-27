# Golden root image for KubeVirt workspaces. Imported directly from the
# Ubuntu Noble cloud image with a 20Gi request: CDI expands imported images
# to the requested size (a PVC *clone* would keep the cloud image's ~3GB
# virtual disk, leaving workspace roots too small to hold docker + tools).
# Workspace VMs boot it read-only via `ephemeral` volumes — a COW overlay per
# VM, discarded on stop — so this single PVC serves every workspace
# concurrently (RWO: fine, single node) and workspace roots are always
# pristine. See iac/coder-template/templates/kubevirt.
resource "kubernetes_manifest" "coder_workspace_golden_image" {
  manifest = {
    apiVersion = "cdi.kubevirt.io/v1beta1"
    kind       = "DataVolume"

    metadata = {
      name      = "coder-workspace-ubuntu-noble"
      namespace = kubernetes_namespace.coder_workspaces.metadata[0].name
    }

    spec = {
      source = {
        http = {
          url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
        }
      }
      storage = {
        resources = {
          requests = {
            storage = "20Gi"
          }
        }
        storageClassName = "openebs-zfs-localpv-general-no-backup"
        accessModes      = ["ReadWriteOnce"]
      }
    }
  }

  wait_for = {
    fields = {
      "status.phase" = "Succeeded"
    }
  }
}
