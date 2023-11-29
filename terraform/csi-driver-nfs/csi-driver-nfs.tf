# this hack is necessary - otherwise large volumes take too long snapshot, causing a timeout
# this timeout value is hardcoded in the templates in the helm chart, hence the find and replace
# I am not a fan of this, maybe I should use democratic-csi?
resource "null_resource" "csi_driver_nfs_repo_clone" {
  triggers = {
    always_run = timestamp()
    version    = "v4.5.0"
  }

  provisioner "local-exec" {
    command = <<-EOF
      git clone --depth 1 -b ${self.triggers.version} https://github.com/kubernetes-csi/csi-driver-nfs.git &&
      mkdir chart &&
      cp -r ./csi-driver-nfs/charts/${self.triggers.version}/csi-driver-nfs/* ./chart/ &&
      sed -i 's/--timeout=1200s/--timeout=79200s/g' ./chart/templates/csi-nfs-controller.yaml
    EOF
  }
}

resource "helm_release" "csi_driver_nfs" {
  name  = "csi-driver-nfs"
  chart = "./chart"

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

  depends_on = [null_resource.csi_driver_nfs_repo_clone]

  lifecycle {
    replace_triggered_by = [null_resource.csi_driver_nfs_repo_clone]
  }
}

resource "null_resource" "csi_driver_nfs_helm_cleanup" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "rm -rf ./chart ./csi-driver-nfs"
  }

  depends_on = [helm_release.csi_driver_nfs]
}
