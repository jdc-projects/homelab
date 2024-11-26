data "http" "kubevirt_yaml" {
  url = "https://github.com/kubevirt/kubevirt/releases/download/${local.kubevirt_version}/kubevirt-cr.yaml"
}

data "kubectl_file_documents" "kubevirt_yaml" {
  content = data.http.kubevirt_yaml.response_body
}

resource "kubectl_manifest" "kubevirt" {
  for_each  = data.kubectl_file_documents.kubevirt_yaml.manifests
  yaml_body = each.value

  depends_on = [
    kubectl_manifest.kubevirt_operator,
  ]
}

resource "null_resource" "kubevirt_readiness_check" {
  provisioner "local-exec" {
    command = <<-EOF
      kubectl -n kubevirt wait kv kubevirt --timeout 5m --for condition=Available
    EOF
  }

  lifecycle {
    replace_triggered_by = [
      kubectl_manifest.kubevirt
    ]
  }
}
