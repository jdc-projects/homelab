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

    # Mark the bulk (1M recordsize - VM-disk-shaped) class as the default for
    # KubeVirt/CDI only. This is NOT a general default StorageClass (normal
    # PVCs are unaffected; all existing DataVolumes pin classes explicitly),
    # but it stops CDINoDefaultStorageClass firing spuriously - with no
    # default SC of either kind, that alert treats any >10m gap in the single
    # kubevirt_cdi_datavolume_pending metric as "a DataVolume is pending"
    # (it did exactly that during the 2026-09-09 Prometheus outage).
    # Key must match CDI's AnnDefaultVirtStorageClass constant.
    annotations = each.key == "bulk_no_backup" ? {
      "storageclass.kubevirt.io/is-default-virt-class" = "true"
    } : {}
  }

  storage_provisioner = "zfs.csi.openebs.io"
  reclaim_policy      = "Delete"

  # based on:
  #  - https://jrs-s.net/2018/08/17/zfs-tuning-cheat-sheet/
  #  - https://www.high-availability.com/docs/ZFS-Tuning-Guide/#:~:text=When%20dealing%20with%20larger%20files,records%20needing%20to%20be%20processed.
  parameters = {
    poolname    = "vault/k3s"
    fstype      = "zfs"
    shared      = "yes"
    xattr       = "sa"
    compression = "lz4"
    atime       = "off"
    recordsize  = each.value.recordsize
    dedup       = "off"
  }
}
