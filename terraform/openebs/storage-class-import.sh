# only for use in an emergency
tofu import 'kubernetes_storage_class.default' default
tofu import 'kubernetes_storage_class.openebs_zfs_localpv["random"]' openebs-zfs-localpv-random
tofu import 'kubernetes_storage_class.openebs_zfs_localpv["general"]' openebs-zfs-localpv-general
tofu import 'kubernetes_storage_class.openebs_zfs_localpv["bulk"]' openebs-zfs-localpv-bulk
tofu import 'kubernetes_storage_class.openebs_zfs_localpv["random_no_backup"]' openebs-zfs-localpv-random-no-backup
tofu import 'kubernetes_storage_class.openebs_zfs_localpv["general_no_backup"]' openebs-zfs-localpv-general-no-backup
tofu import 'kubernetes_storage_class.openebs_zfs_localpv["bulk_no_backup"]' openebs-zfs-localpv-bulk-no-backup
