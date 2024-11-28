resource "kubernetes_manifest" "kubevirt_instance" {
  manifest = {
    apiVersion = "kubevirt.io/v1"
    kind       = "KubeVirt"

    metadata = {
      name      = "kubevirt"
      namespace = data.kubernetes_namespace.kubevirt.metadata[0].name
    }

    spec = {
      certificateRotateStrategy = {}
      configuration = {
        developerConfiguration = {
          featureGates = []
        }
      }
      customizeComponents    = {}
      imagePullPolicy        = "IfNotPresent"
      workloadUpdateStrategy = {}
    }
  }
}

resource "null_resource" "kubevirt_readiness_check" {
  provisioner "local-exec" {
    command = <<-EOF
      kubectl -n ${kubernetes_manifest.kubevirt_instance.manifest.metadata.namespace} wait kubevirt ${kubernetes_manifest.kubevirt_instance.manifest.metadata.name} --timeout 5m --for condition=Available
    EOF
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_manifest.kubevirt_instance
    ]
  }
}
