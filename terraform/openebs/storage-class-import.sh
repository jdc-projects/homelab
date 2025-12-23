# only for use in an emergency
terraform import 'kubernetes_storage_class.default' default
terraform import 'kubernetes_storage_class.openebs_zfs_localpv["random"]' openebs-zfs-localpv-random
terraform import 'kubernetes_storage_class.openebs_zfs_localpv["general"]' openebs-zfs-localpv-general
terraform import 'kubernetes_storage_class.openebs_zfs_localpv["bulk"]' openebs-zfs-localpv-bulk
terraform import 'kubernetes_storage_class.openebs_zfs_localpv["random_no_backup"]' openebs-zfs-localpv-random-no-backup
terraform import 'kubernetes_storage_class.openebs_zfs_localpv["general_no_backup"]' openebs-zfs-localpv-general-no-backup
terraform import 'kubernetes_storage_class.openebs_zfs_localpv["bulk_no_backup"]' openebs-zfs-localpv-bulk-no-backup
