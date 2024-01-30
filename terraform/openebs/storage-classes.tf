resource "kubernetes_storage_class" "default" {
  metadata {
    name = "default"

    annotations = {
      "storageclass.kubernetes.io/is-default-class" = true
    }
  }

  storage_provisioner = "device.csi.openebs.io"
  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"

  depends_on = [
    helm_release.openebs,
  ]
}

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

  depends_on = [
    helm_release.openebs,
  ]
}
