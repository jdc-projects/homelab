module "grafana_ingress" {
  source = "../modules/ingress"

  name      = "grafana"
  namespace = data.terraform_remote_state.prometheus_operator.outputs.prometheus_operator_helm_release_namespace
  domain    = data.terraform_remote_state.prometheus_operator.outputs.grafana_domain

  target_port = 80

  existing_service_name      = "${data.terraform_remote_state.prometheus_operator.outputs.prometheus_operator_helm_release_name}-grafana"
  existing_service_namespace = data.terraform_remote_state.prometheus_operator.outputs.prometheus_operator_helm_release_namespace
}
