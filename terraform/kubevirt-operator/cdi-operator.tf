data "http" "cdi_operator_yaml" {
  url = "https://github.com/kubevirt/containerized-data-importer/releases/download/${local.cdi_version}/cdi-operator.yaml"
}

data "kubectl_file_documents" "cdi_operator_yaml" {
  content = data.http.cdi_operator_yaml.response_body
}

resource "kubectl_manifest" "cdi_operator" {
  for_each  = data.kubectl_file_documents.cdi_operator_yaml.manifests
  yaml_body = each.value
}
