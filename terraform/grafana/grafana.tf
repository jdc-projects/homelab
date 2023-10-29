resource "helm_release" "grafana" {
  name = "grafana"

  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "6.61.1"

  namespace = kubernetes_namespace.grafana.metadata[0].name

  timeout = 300

  set {
    name  = "ingress.enabled"
    value = "true"
  }
  set {
    name  = "ingress.hosts[0]"
    value = "grafana.${var.server_base_domain}"
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }
  set {
    name  = "persistence.size"
    value = kubernetes_persistent_volume_claim.grafana.spec[0].resources[0].requests.storage
  }
  set {
    name  = "persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.grafana.metadata[0].name
  }

  set_sensitive {
    name  = "adminUser"
    value = random_password.admin_username.result
  }
  set_sensitive {
    name  = "adminPassword"
    value = random_password.admin_password.result
  }
  set {
    name  = "datasources.datasources\\.yaml.apiVersion"
    value = "1"
  }
  set {
    name  = "datasources.datasources\\.yaml.datasources[0].name"
    value = "Loki"
  }
  set {
    name  = "datasources.datasources\\.yaml.datasources[0].type"
    value = "loki"
  }
  set {
    name  = "datasources.datasources\\.yaml.datasources[0].access"
    value = "proxy"
  }
  set {
    name  = "datasources.datasources\\.yaml.datasources[0].url"
    value = "http://loki-gateway.${data.terraform_remote_state.loki.outputs.namespace}"
  }
  set {
    name  = "datasources.datasources\\.yaml.datasources[0].basicAuth"
    value = "true"
  }
  set_sensitive {
    name  = "datasources.datasources\\.yaml.datasources[0].basicAuthUser"
    value = data.terraform_remote_state.loki.outputs.gateway_username
  }
  set_sensitive {
    name  = "datasources.datasources\\.yaml.datasources[0].secureJsonData.basicAuthPassword"
    value = data.terraform_remote_state.loki.outputs.gateway_password
  }

  set {
    name  = "grafana\\.ini.server.root_url"
    value = "https://grafana.${var.server_base_domain}"
  }
  set {
    name  = "grafana\\.ini.auth\\.generic_oauth.enabled"
    value = "true"
  }
  set {
    name  = "grafana\\.ini.auth\\.generic_oauth.name"
    value = "keycloak"
  }
  set {
    name  = "grafana\\.ini.auth\\.generic_oauth.allow_sign_up"
    value = "true"
  }
  set {
    name  = "grafana\\.ini.auth\\.generic_oauth.client_id"
    value = keycloak_openid_client.grafana.client_id
  }
  set_sensitive {
    name  = "grafana\\.ini.auth\\.generic_oauth.client_secret"
    value = random_password.keycloak_client_secret.result
  }
  set {
    name  = "grafana\\.ini.auth\\.generic_oauth.scopes"
    value = "openid"
  }
  set {
    name  = "grafana\\.ini.auth\\.generic_oauth.email_attribute_path"
    value = "email"
  }
  set {
    name  = "grafana\\.ini.auth\\.generic_oauth.login_attribute_path"
    value = "preferred_username"
  }
  set {
    name  = "grafana\\.ini.auth\\.generic_oauth.name_attribute_path"
    value = "name"
  }
  set {
    name  = "grafana\\.ini.auth\\.generic_oauth.auth_url"
    value = "https://idp.${var.server_base_domain}/realms/${data.terraform_remote_state.keycloak_config.outputs.server_base_domain_realm_id}/protocol/openid-connect/auth"
  }
  set {
    name  = "grafana\\.ini.auth\\.generic_oauth.token_url"
    value = "https://idp.${var.server_base_domain}/realms/${data.terraform_remote_state.keycloak_config.outputs.server_base_domain_realm_id}/protocol/openid-connect/token"
  }
  set {
    name  = "grafana\\.ini.auth\\.generic_oauth.api_url"
    value = "https://idp.${var.server_base_domain}/realms/${data.terraform_remote_state.keycloak_config.outputs.server_base_domain_realm_id}/protocol/openid-connect/userinfo"
  }
  set {
    name  = "grafana\\.ini.auth\\.generic_oauth.role_attribute_strict"
    value = "true"
  }
  set {
    name  = "grafana\\.ini.auth\\.generic_oauth.role_attribute_path"
    value = "contains(roles[*]\\, '${keycloak_role.grafana_admin.name}') && 'GrafanaAdmin'"
  }
  set {
    name  = "grafana\\.ini.auth\\.generic_oauth.auto_login"
    value = "true"
  }
}
