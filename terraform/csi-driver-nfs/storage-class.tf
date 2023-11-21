resource "kubernetes_storage_class" "nfs" {
  metadata {
    name = "csi-nfs"

    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "nfs.csi.k8s.io"
  reclaim_policy      = "Delete"
  volume_binding_mode = "Immediate"

  mount_options = [
    "nfsvers=4.2",
  ]

  parameters = {
    server = var.nfs_ip_address
    share  = var.nfs_share
  }

  depends_on = [helm_release.csi_driver_nfs]
}
