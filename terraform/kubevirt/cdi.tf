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

locals {
  cdi_uploadproxy_name = "${kubernetes_manifest.cdi_instance.manifest.metadata.name}-uploadproxy"
}

module "cdi_uploadproxy_ingress" {
  source = "../modules/ingress"

  name      = local.cdi_uploadproxy_name
  namespace = data.kubernetes_namespace.cdi.metadata[0].name
  domain    = "${local.cdi_uploadproxy_name}.${var.server_base_domain}"

  target_port = 443

  existing_service_name      = local.cdi_uploadproxy_name
  existing_service_namespace = data.kubernetes_namespace.cdi.metadata[0].name
}
