resource "helm_release" "snapshot_controller" {
  name = "snapshot-controller"

  repository = "https://democratic-csi.github.io/charts/"
  chart      = "snapshot-controller"
  version    = "0.2.4"

  namespace = kubernetes_namespace.democratic_csi.metadata[0].name

  timeout = 300
}
