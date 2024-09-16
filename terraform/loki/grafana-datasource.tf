resource "kubernetes_manifest" "loki_grafana_datasource" {
  manifest = {
    apiVersion = "grafana.integreatly.org/v1beta1"
    kind       = "GrafanaDatasource"

    metadata = {
      name      = "loki"
      namespace = kubernetes_namespace.loki.metadata[0].name
    }

    spec = {
      allowCrossNamespaceImport = "true"

      instanceSelector = {
        matchLabels = data.terraform_remote_state.grafana.outputs.grafana_deployment_labels
      }

      datasource = {
        name = "Loki"
        type = "loki"

        access = "proxy"

        url = "http://${helm_release.loki.name}-gateway.${kubernetes_namespace.loki.metadata[0].name}"

        basicAuth     = "true"
        basicAuthUser = random_password.gateway_username.result

        secureJsonData = {
          basicAuthPassword = random_password.gateway_password.result
        }
      }
    }
  }
}
