resource "helm_release" "democratic_csi" {
  name = "democratic-csi"

  repository = "https://democratic-csi.github.io/charts/"
  chart      = "democratic-csi"
  version    = "0.14.2"

  namespace = kubernetes_namespace.democratic_csi.metadata[0].name

  timeout = 300

  set {
    name  = "csiDriver.name"
    value = "org.democratic-csi.nfs"
  }

  set {
    name  = "storageClasses[0].name"
    value = "truenas-nfs-csi"
  }
  set {
    name  = "storageClasses[0].defaultClass"
    value = "true"
  }
  set {
    name  = "storageClasses[0].reclaimPolicy"
    value = "Delete"
  }
  set {
    name  = "storageClasses[0].volumeBindingMode"
    value = "Immediate"
  }
  set {
    name  = "storageClasses[0].allowVolumeExpansion"
    value = "true"
  }
  set {
    name  = "storageClasses[0].parameters.fsType"
    value = "nfs"
  }
  set {
    name  = "storageClasses[0].mountOptions[0]"
    value = "noatime"
  }
  set {
    name  = "storageClasses[0].mountOptions[1]"
    value = "nfsvers=4.2"
  }

  set {
    name  = "storageClasses[1].name"
    value = "truenas-nfs-csi-no-backup"
  }
  set {
    name  = "storageClasses[1].defaultClass"
    value = "false"
  }
  set {
    name  = "storageClasses[1].reclaimPolicy"
    value = "Delete"
  }
  set {
    name  = "storageClasses[1].volumeBindingMode"
    value = "Immediate"
  }
  set {
    name  = "storageClasses[1].allowVolumeExpansion"
    value = "true"
  }
  set {
    name  = "storageClasses[1].parameters.fsType"
    value = "nfs"
  }
  set {
    name  = "storageClasses[1].mountOptions[0]"
    value = "noatime"
  }
  set {
    name  = "storageClasses[1].mountOptions[1]"
    value = "nfsvers=4.2"
  }

  set {
    name  = "volumeSnapshotClasses[0].name"
    value = "truenas-nfs-csi"
  }
  set {
    name  = "volumeSnapshotClasses[0].annotations.snapshot\\.storage\\.kubernetes\\.io/is-default-class"
    value = "true"
    type  = "string"
  }
  set {
    name  = "volumeSnapshotClasses[0].annotations.velero\\.io/csi-volumesnapshot-class"
    value = "true"
    type  = "string"
  }
  set {
    name  = "volumeSnapshotClasses[0].labels.velero\\.io/csi-volumesnapshot-class"
    value = "true"
    type  = "string"
  }
  set {
    name  = "volumeSnapshotClasses[0].deletionPolicy"
    value = "Delete"
  }

  set {
    name  = "driver.config.driver"
    value = "freenas-api-nfs" # this name is important, can't be changed to truenas
  }
  set {
    name  = "driver.config.httpConnection.protocol"
    value = "https"
  }
  set_sensitive {
    name  = "driver.config.httpConnection.host"
    value = var.truenas_ip_address
  }
  set {
    name  = "driver.config.httpConnection.port"
    value = "443"
  }
  set_sensitive {
    name  = "driver.config.httpConnection.apiKey"
    value = var.truenas_api_key
  }
  set {
    name  = "driver.config.httpConnection.allowInsecure"
    value = "true"
  }
  set {
    name  = "driver.config.zfs.datasetProperties.org\\.freenas\\:description"
    value = "\"{{ parameters.[csi.storage.k8s.io/pvc/namespace] }}/{{ parameters.[csi.storage.k8s.io/pvc/name] }}\""
  }
  set {
    name  = "driver.config.zfs.datasetParentName"
    value = var.truenas_k3s_dataset
  }
  set {
    name  = "driver.config.zfs.detachedSnapshotsDatasetParentName"
    value = var.truenas_k3s_snapshot_dataset
  }
  set {
    name  = "driver.config.zfs.datasetEnableQuotas"
    value = "true"
  }
  set {
    name  = "driver.config.zfs.datasetEnableReservation"
    value = "false"
  }
  set {
    name  = "driver.config.zfs.datasetPermissionsMode"
    value = "0777"
  }
  set {
    name  = "driver.config.zfs.datasetPermissionsUser"
    value = "0"
  }
  set {
    name  = "driver.config.zfs.datasetPermissionsGroup"
    value = "0"
  }
  set_sensitive {
    name  = "driver.config.nfs.shareHost"
    value = var.truenas_ip_address
  }
  set {
    name  = "driver.config.nfs.shareAllowedNetworks[0]"
    value = "10.42.0.0/16"
  }
  set {
    name  = "driver.config.nfs.shareAllowedNetworks[1]"
    value = "10.43.0.0/16"
  }
  set {
    name  = "driver.config.nfs.shareAllowedNetworks[2]"
    value = "192.168.1.0/24"
  }
  set {
    name  = "driver.config.nfs.shareMaprootUser"
    value = "root"
  }
  set {
    name  = "driver.config.nfs.shareMaprootGroup"
    value = "root"
  }
  set {
    name  = "driver.config.nfs.shareCommentTemplate"
    value = "\"{{ parameters.[csi.storage.k8s.io/pvc/namespace] }}/{{ parameters.[csi.storage.k8s.io/pvc/name] }}\""
  }
}
