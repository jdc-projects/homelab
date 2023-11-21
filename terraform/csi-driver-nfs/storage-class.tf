resource "kubernetes_storage_class" "nfs" {
  metadata {
    name = "nfs"

    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "nfs.csi.k8s.io"
  reclaim_policy = "Delete"
  volume_binding_mode = "Immediate"

  mount_options = [
    "nfsvers=4.1",
  ]

  parameters = {
    server = "192.168.1.250"
    share  = "/mnt/vault/exclude/k3s"
  }

  depends_on = [ helm_release.csi_driver_nfs ]
}
