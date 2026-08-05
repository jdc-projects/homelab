# https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
#
# This module installs ONLY the Prometheus operator and its CRDs. The actual
# Prometheus instance, Alertmanager, exporters and default rules are deployed
# by the sibling `iac/prometheus/` module, which re-uses this operator.
#
# Chart version is exported via outputs.tf so the instance module can pin to
# the exact same version through terraform_remote_state - keeping them in sync
# is required (CRDs from this install must match what the instance templates
# against).

locals {
  kube_prometheus_stack_version = "88.1.2"
}

resource "helm_release" "kube_prometheus_stack_operator" {
  name = "kube-prometheus-stack"

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = local.kube_prometheus_stack_version

  namespace = kubernetes_namespace.prometheus_operator.metadata[0].name

  timeout = 600

  # Operator + CRDs only. Everything else lives in iac/prometheus/.
  # The subchart dependencies are gated by their parent camelCase conditions
  # (see the chart's Chart.yaml), not the dashed subchart-internal values.
  # The cluster-component templates (coreDns, kubelet, kubeApiServer, etc.)
  # install headless Services in kube-system and would conflict with the
  # instance module's install, so they're disabled here too.
  set = [
    {
      name  = "crds.enabled"
      value = "true"
    },
    {
      name  = "prometheusOperator.enabled"
      value = "true"
    },
    {
      name  = "prometheus.enabled"
      value = "false"
    },
    {
      name  = "alertmanager.enabled"
      value = "false"
    },
    {
      name  = "grafana.enabled"
      value = "false"
    },
    {
      name  = "nodeExporter.enabled"
      value = "false"
    },
    {
      name  = "kubeStateMetrics.enabled"
      value = "false"
    },
    {
      name  = "defaultRules.create"
      value = "false"
    },
    # Cluster-component monitors - owned by iac/prometheus/.
    {
      name  = "kubeApiServer.enabled"
      value = "false"
    },
    {
      name  = "kubelet.enabled"
      value = "false"
    },
    {
      name  = "kubeControllerManager.enabled"
      value = "false"
    },
    {
      name  = "coreDns.enabled"
      value = "false"
    },
    {
      name  = "kubeEtcd.enabled"
      value = "false"
    },
    {
      name  = "kubeScheduler.enabled"
      value = "false"
    },
    {
      name  = "kubeProxy.enabled"
      value = "false"
    },
  ]
}
