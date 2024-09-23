locals {
  knative_operator_version = "v1.15.4"
}

data "http" "knative_operator_yaml" {
  url = "https://github.com/knative/operator/releases/download/knative-${local.knative_operator_version}/operator.yaml"
}

data "kubectl_file_documents" "knative_operator_yaml" {
  content = data.http.knative_operator_yaml.response_body
}

resource "kubectl_manifest" "knative_operator" {
  for_each  = data.kubectl_file_documents.knative_operator_yaml.manifests
  yaml_body = each.value
}
