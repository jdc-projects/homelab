resource "kubernetes_storage_class" "openebs_zfs_localpv" {
  for_each = tomap({
    random = tomap({
      is_included_in_backup = true
      recordsize            = "64k"
    })
    general = tomap({
      is_included_in_backup = true
      recordsize            = "128k"
    })
    mass = tomap({
      is_included_in_backup = true
      recordsize            = "1m"
    })
    random_no_backup = tomap({
      is_included_in_backup = false
      recordsize            = "64k"
    })
    general_no_backup = tomap({
      is_included_in_backup = false
      recordsize            = "128k"
    })
    mass_no_backup = tomap({
      is_included_in_backup = false
      recordsize            = "1m"
    })
  })

  metadata {
    name = format("openebs-zfs-localpv-${each.key}%s", each.value.is_included_in_backup ? "" : "-no-backup")
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
