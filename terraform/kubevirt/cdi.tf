data "http" "cdi_yaml" {
  url = "https://github.com/kubevirt/containerized-data-importer/releases/download/${local.cdi_version}/cdi-cr.yaml"
}

data "kubectl_file_documents" "cdi_yaml" {
  content = data.http.cdi_yaml.response_body
}

resource "kubectl_manifest" "cdi" {
  for_each  = data.kubectl_file_documents.cdi_yaml.manifests
  yaml_body = each.value

  depends_on = [
    kubectl_manifest.cdi_operator,
  ]
}

resource "null_resource" "cdi_readiness_check" {
  provisioner "local-exec" {
    command = <<-EOF
      kubectl -n cdi wait cdi cdi --timeout 5m --for condition=Available
    EOF
  }

  lifecycle {
    replace_triggered_by = [
      kubectl_manifest.kubevirt
    ]
  }
}

module "cdi_uploadproxy_ingress" {
  source = "../modules/ingress"

  name      = "cdi-uploadproxy"
  namespace = "cdi"
  domain    = "cdi-uploadproxy.${var.server_base_domain}"

  target_port = 443

  existing_service_name      = "cdi-uploadproxy"
  existing_service_namespace = "cdi"
}
