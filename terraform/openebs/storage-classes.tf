resource "kubernetes_storage_class" "openebs_zfs_localpv" {
  for_each = tomap({
    random = tomap({
      name_suffix = "random"
      recordsize  = "64k"
    })
    general = tomap({
      name_suffix = "general"
      recordsize  = "128k"
    })
    bulk = tomap({
      name_suffix = "bulk"
      recordsize  = "1m"
    })
    random_no_backup = tomap({
      name_suffix = "random-no-backup"
      recordsize  = "64k"
    })
    general_no_backup = tomap({
      name_suffix = "general-no-backup"
      recordsize  = "128k"
    })
    bulk_no_backup = tomap({
      name_suffix = "bulk-no-backup"
      recordsize  = "1m"
    })
  })

  metadata {
    name = "openebs-zfs-localpv-${each.value.name_suffix}"
  }

  storage_provisioner = "zfs.csi.openebs.io"
  reclaim_policy      = "Delete"

  parameters = {
    poolname    = "vault"
    fstype      = "zfs"
    xattr       = "sa"
    compression = "lz4"
    atime       = "off"
    recordsize  = each.value.recordsize
    dedup       = "off"
  }

  depends_on = [
    helm_release.openebs,
  ]
}
