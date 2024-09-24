data "http" "net_gateway_api_yaml" {
  url = "https://github.com/knative-extensions/net-gateway-api/releases/download/knative-v${local.net_gateway_api_version}/net-gateway-api.yaml"
}

data "kubectl_file_documents" "net_gateway_api_yaml" {
  content = data.http.net_gateway_api_yaml.response_body
}

resource "kubernetes_config_map" "config_gateway" {
  metadata {
    name = "config-gateway"
    namespace = kubernetes_namespace.knative["serving"].metadata[0].name
  }

  data = {
    # ***** class may need defining
    external-gateways = <<-EOF
      - class: traefik
        gateway: traefik/traefik-gateway
    EOF

    internal-gateways = <<-EOF
      - class: traefik
        gateway: traefik/traefik-gateway
    EOF
  }

}

resource "kubectl_manifest" "net_gateway_api" {
  for_each  = {for k, v in data.kubectl_file_documents.net_gateway_api_yaml.manifests : k => v if k != "/api/v1/namespaces/knative-serving/configmaps/config-gateway"}
  yaml_body = each.value

  depends_on = [
    kubernetes_manifest.knative_serving,
    kubernetes_config_map.config_gateway,
  ]
}
