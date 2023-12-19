resource "kubernetes_manifest" "snapshot_class_openebs_zfs_localpv" {
  for_each = kubernetes_storage_class.openebs_zfs_localpv

  manifest = {
    apiVersion = "snapshot.storage.k8s.io/v1"
    kind       = "VolumeSnapshotClass"

    metadata = {
      name = "openebs-zfs-localpv"
    }

    driver         = "zfs.csi.openebs.io"
    deletionPolicy = "Delete"

    parameters = {
      poolname    = "vault"
      fstype      = "zfs"
      xattr       = "sa"
      compression = "lz4"
      atime       = "off"
      recordsize  = "128k"
      dedup       = "off"
    }
  }

  depends_on = [
    helm_release.openebs,
  ]
}
