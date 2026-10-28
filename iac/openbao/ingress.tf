# OpenBao fronts its own auth (Keycloak OIDC via iac/openbao-config, plus the
# raw API for CLI/health/OIDC-callback flows), so no edge auth — same choice
# as sentry/outline/grafana. AppSec is disabled for the same reason as
# sentry: API-heavy, non-browser traffic would just trip WAF rules.
module "openbao_ingress" {
  source = "../modules/ingress"

  name      = "openbao"
  namespace = kubernetes_namespace.openbao.metadata[0].name
  domain    = local.openbao_domain

  existing_service_name      = "openbao"
  existing_service_namespace = kubernetes_namespace.openbao.metadata[0].name
  target_port                = 8200

  auth_mode                         = "none"
  do_enable_crowdsec_bouncer_appsec = false
}
