resource "helm_release" "csi_driver_nfs" {
  name = "csi-driver-nfs"

  repository = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts"
  chart      = "csi-driver-nfs"
  version    = "4.5.0"

  namespace = kubernetes_namespace.csi_driver_nfs.metadata[0].name

  timeout = 300

  set {
    name  = "controller.logLevel"
    value = "9"
  }

  set {
    name  = "node.logLevel"
    value = "9"
  }

  set {
    name  = "externalSnapshotter.enabled"
    value = "true"
  }
  set {
    name  = "externalSnapshotter.controller.replicas"
    value = "4"
  }
}
