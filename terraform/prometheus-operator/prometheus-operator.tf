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
  oauth_logout_url      = "${local.oauth_url_base}/logout"
  oauth_admin_role_name = "grafanaAdmin"
}

resource "helm_release" "prometheus_operator" {
  name      = "prometheus-operator"
  namespace = kubernetes_namespace.prometheus_operator.metadata[0].name

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "60.0.0"

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
  # I should fix this in a better way in the future
  set {
    name  = "grafana.assertNoLeakedSecrets"
    value = "false"
  }
}

# resource "null_resource" "crd_updates" {
#   lifecycle {
#     replace_triggered_by = [
#       helm_release.prometheus_operator,
#     ]
#   }

#   provisioner "local-exec" {
#     when    = create
#     command = <<-EOF
#       kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${helm_release.prometheus_operator.app_version}/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagerconfigs.yaml
#       kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${helm_release.prometheus_operator.app_version}/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
#       kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${helm_release.prometheus_operator.app_version}/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
#       kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${helm_release.prometheus_operator.app_version}/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml
#       kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${helm_release.prometheus_operator.app_version}/example/prometheus-operator-crd/monitoring.coreos.com_prometheusagents.yaml
#       kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${helm_release.prometheus_operator.app_version}/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
#       kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${helm_release.prometheus_operator.app_version}/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
#       kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${helm_release.prometheus_operator.app_version}/example/prometheus-operator-crd/monitoring.coreos.com_scrapeconfigs.yaml
#       kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${helm_release.prometheus_operator.app_version}/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
#       kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${helm_release.prometheus_operator.app_version}/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml
#     EOF
#   }
# }
