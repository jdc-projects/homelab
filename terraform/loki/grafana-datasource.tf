# ***** replace with CRD

# resource "grafana_data_source" "loki" {
#   name = "Loki"
#   type = "loki"

#   url = "http://loki-gateway.${kubernetes_namespace.loki.metadata[0].name}"

#   basic_auth_enabled  = true
#   basic_auth_username = random_password.gateway_username.result

#   secure_json_data_encoded = jsonencode({
#     basicAuthPassword = random_password.gateway_password.result
#   })
# }
