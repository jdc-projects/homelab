# CDI (KubeVirt's containerized-data-importer) creates a StorageProfile per
# StorageClass but cannot infer capabilities for the unrecognized
# zfs.csi.openebs.io provisioner, leaving every profile "incomplete" and
# CDIStorageProfilesIncomplete / CDIDefaultStorageClassDegraded firing.
# Declare the capability set explicitly instead: all classes here are
# Filesystem-mode and set shared: "yes", so RWO + RWX.
#
# Deleting a StorageClass cascades: CDI deletes its StorageProfile and
# recreates it empty on return, losing this spec. That happened on 2026-08-30
# when the openebs-* classes were accidentally recreated (cc7b884/d0eef77),
# which is when these alerts started. Managing the spec here makes the
# declaration survive - a recreated profile is immediately re-declared.
#
# Existing profiles were imported into state; the CDI operator keeps
# ownership of labels/ownerReferences/status (server-side apply).
resource "kubernetes_manifest" "cdi_storage_profile" {
  for_each = kubernetes_storage_class.openebs_zfs_localpv

  manifest = {
    apiVersion = "cdi.kubevirt.io/v1beta1"
    kind       = "StorageProfile"

    metadata = {
      name = kubernetes_storage_class.openebs_zfs_localpv[each.key].metadata[0].name
    }

    spec = {
      claimPropertySets = [
        {
          accessModes = ["ReadWriteOnce", "ReadWriteMany"]
          volumeMode  = "Filesystem"
        },
      ]
    }
  }
}
