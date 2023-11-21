resource "kubernetes_storage_class" "nfs" {
  metadata {
    name = "csi-nfs"

    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "nfs.csi.k8s.io"
  reclaim_policy = "Delete"
  volume_binding_mode = "Immediate"

  mount_options = [
    "nfsvers=4.2",
  ]

  parameters = {
    server = var.nfs_ip_address
    share  = var.nfs_share
  }

  depends_on = [ helm_release.csi_driver_nfs ]
}

resource "kubernetes_manifest" "nfs_volume_snapshot_class" {
  manifest = {
    apiVersion = "snapshot.storage.k8s.io/v1"
    kind       = "VolumeSnapshotClass"

    metadata = {
      name     = "csi-nfs"

      labels = {
        "velero.io/csi-volumesnapshot-class" = "true"
      }

      annotations = {
        "snapshot.storage.kubernetes.io/is-default-class" = "true"
      }
    }

    deletionPolicy = "Delete"

    driver = "nfs.csi.k8s.io"
  }
}
