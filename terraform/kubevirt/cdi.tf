resource "kubernetes_manifest" "cdi_instance" {
  manifest = {
    apiVersion = "cdi.kubevirt.io/v1beta1"
    kind       = "CDI"

    metadata = {
      name = "cdi"
    }

    spec = {
      config = {
        featureGates = [
          "HonorWaitForFirstConsumer",
        ]
        scratchSpaceStorageClass = "openebs-zfs-localpv-bulk-no-backup"
      }
      imagePullPolicy = "IfNotPresent"
      infra = {
        nodeSelector = {
          "kubernetes.io/os" = "linux"
        }
        tolerations = [
          {
            key      = "CriticalAddonsOnly"
            operator = "Exists"
          },
        ]
      }
      workload = {
        nodeSelector = {
          "kubernetes.io/os" = "linux"
        }
      }
    }
  }
}

resource "null_resource" "cdi_readiness_check" {
  provisioner "local-exec" {
    command = <<-EOF
      kubectl wait cdi ${kubernetes_manifest.cdi_instance.manifest.metadata.name} --timeout 5m --for condition=Available
    EOF
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_manifest.cdi_instance
    ]
  }
}

resource "kubernetes_service" "cdi_uploadproxy_nodeport" {
  metadata {
    name      = "cdi-uploadproxy-nodeport"
    namespace = "cdi"

    labels = {
      "cdi.kubevirt.io" = "cdi-uploadproxy"
    }
  }

  spec {
    type = "NodePort"

    selector = {
      "cdi.kubevirt.io" = "cdi-uploadproxy"
    }

    port {
      port        = 443
      target_port = 8443
      node_port   = 31001
      protocol    = "TCP"
    }
  }
}
