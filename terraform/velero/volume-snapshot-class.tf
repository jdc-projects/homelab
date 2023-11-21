resource "kubernetes_manifest" "nfs_volume_snapshot_class" {
  manifest = {
    apiVersion = "snapshot.storage.k8s.io/v1"
    kind       = "VolumeSnapshotClass"

    metadata = {
      name = "csi-nfs"

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
