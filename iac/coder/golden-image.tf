# Golden root image for KubeVirt workspaces. Imported directly from the
# Ubuntu Resolute (26.04 LTS) cloud image with a 20Gi request: CDI expands
# imported images to the requested size (a PVC *clone* would keep the cloud
# image's ~3GB virtual disk, leaving workspace roots too small to hold
# docker + tools). Workspace VMs boot it read-only via `ephemeral` volumes —
# a COW overlay per VM, discarded on stop — so this single PVC serves every
# workspace concurrently (RWO: fine, single node) and workspace roots are
# always pristine. See iac/coder-template/templates/kubevirt.
#
# Upgrades: the golden is frozen at import; re-import deliberately (e.g.
# `tofu taint kubernetes_manifest.coder_workspace_golden_image`) when you
# want a newer point release.
resource "kubernetes_manifest" "coder_workspace_golden_image" {
  manifest = {
    apiVersion = "cdi.kubevirt.io/v1beta1"
    kind       = "DataVolume"

    metadata = {
      name      = "coder-workspace-ubuntu-resolute"
      namespace = kubernetes_namespace.coder_workspaces.metadata[0].name
    }

    spec = {
      source = {
        http = {
          url = "https://cloud-images.ubuntu.com/resolute/current/resolute-server-cloudimg-amd64.img"
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
