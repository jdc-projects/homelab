data "http" "kubevirt_operator_yaml" {
  url = "https://github.com/kubevirt/kubevirt/releases/download/${local.kubevirt_version}/kubevirt-operator.yaml"
}

data "kubectl_file_documents" "kubevirt_operator_yaml" {
  content = data.http.kubevirt_operator_yaml.response_body
}

resource "kubectl_manifest" "kubevirt_operator" {
  for_each  = data.kubectl_file_documents.kubevirt_operator_yaml.manifests
  yaml_body = each.value
}
