locals {
  grafana_domain        = "grafana.${var.server_base_domain}"
  oauth_client_id       = "grafana"
  oauth_subdomain       = "idp"
  oauth_domain          = "${local.oauth_subdomain}.${var.server_base_domain}"
  oauth_realm_name      = var.server_base_domain
  oauth_url_base        = "https://${local.oauth_domain}/realms/${local.oauth_realm_name}/protocol/openid-connect"
  oauth_auth_url        = "${local.oauth_url_base}/auth"
  oauth_token_url       = "${local.oauth_url_base}/token"
  oauth_api_url         = "${local.oauth_url_base}/userinfo"
  oauth_admin_role_name = "grafanaAdmin"
}

resource "helm_release" "prometheus_operator" {
  name      = "prometheus-operator"
  namespace = kubernetes_namespace.prometheus_operator.metadata[0].name

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "55.5.1"

  timeout = 300

  set {
    name  = "grafana.defaultDashboardsEditable"
    value = "false"
  }
  set_sensitive {
    name  = "grafana.adminPassword"
    value = random_password.grafana_admin_password.result
  }
  set {
    name  = "grafana.ingress.enabled"
    value = "true"
  }
  set_list {
    name = "grafana.ingress.hosts"
    value = [
      local.grafana_domain,
    ]
  }

  set {
    name  = "grafana.grafana\\.ini.server.root_url"
    value = "https://${local.grafana_domain}"
  }
  set {
    name  = "grafana.grafana\\.ini.auth\\.generic_oauth.enabled"
    value = "true"
  }
  set {
    name  = "grafana.grafana\\.ini.auth\\.generic_oauth.name"
    value = "keycloak"
  }
  set {
    name  = "grafana.grafana\\.ini.auth\\.generic_oauth.allow_sign_up"
    value = "true"
  }
  set {
    name  = "grafana.grafana\\.ini.auth\\.generic_oauth.client_id"
    value = local.oauth_client_id
  }
  set_sensitive {
    name  = "grafana.grafana\\.ini.auth\\.generic_oauth.client_secret"
    value = random_password.oauth_client_secret.result
  }
  set {
    name  = "grafana.grafana\\.ini.auth\\.generic_oauth.scopes"
    value = "openid"
  }
  set {
    name  = "grafana.grafana\\.ini.auth\\.generic_oauth.email_attribute_path"
    value = "email"
  }
  set {
    name  = "grafana.grafana\\.ini.auth\\.generic_oauth.login_attribute_path"
    value = "preferred_username"
  }
  set {
    name  = "grafana.grafana\\.ini.auth\\.generic_oauth.name_attribute_path"
    value = "name"
  }
  set {
    name  = "grafana.grafana\\.ini.auth\\.generic_oauth.auth_url"
    value = local.oauth_auth_url
  }
  set {
    name  = "grafana.grafana\\.ini.auth\\.generic_oauth.token_url"
    value = local.oauth_token_url
  }
  set {
    name  = "grafana.grafana\\.ini.auth\\.generic_oauth.api_url"
    value = local.oauth_api_url
  }
  set {
    name  = "grafana.grafana\\.ini.auth\\.generic_oauth.role_attribute_strict"
    value = "true"
  }
  set {
    name  = "grafana.grafana\\.ini.auth\\.generic_oauth.role_attribute_path"
    value = "contains(roles[*]\\, '${local.oauth_admin_role_name}') && 'GrafanaAdmin'"
  }
  set {
    name  = "grafana.grafana\\.ini.auth\\.generic_oauth.auto_login"
    value = "true"
  }
}
