locals {
  oauth_client_id       = "grafana"
  oauth_subdomain       = "idp"
  oauth_domain          = "${local.oauth_subdomain}.${var.server_base_domain}"
  oauth_realm_name      = var.server_base_domain
  oauth_url_base        = "https://${local.oauth_domain}/realms/${local.oauth_realm_name}/protocol/openid-connect"
  oauth_auth_url = "${local.oauth_url_base}/auth"
  oauth_token_url = "${local.oauth_url_base}/token"
  oauth_api_url = "${local.oauth_url_base}/userinfo"
  oauth_admin_role_name = "grafanaAdmin"
}

resource "kubernetes_config_map" "etc_grafana" {
  metadata {
    name      = "etc-grafana"
    namespace = kubernetes_namespace.prometheus_operator.metadata[0].name
  }

  data = {
    "grafana.ini" = <<-EOF
      [auth.generic_oauth]
      enabled = true
      name = keycloak
      allow_sign_up = true
      client_id = ${local.oauth_client_id}
      client_secret = ${random_password.oauth_client_secret.result}
      scopes = openid
      email_attribute_path = email
      login_attribute_path = preferred_username
      name_attribute_path = name
      auth_url = ${local.oauth_auth_url}
      token_url = ${local.oauth_token_url}
      api_url = ${local.oauth_api_url}
      role_attribute_strict = true
      role_attribute_path = contains(roles[*], '${local.oauth_admin_role_name}') && 'GrafanaAdmin'
    EOF
  }
}
