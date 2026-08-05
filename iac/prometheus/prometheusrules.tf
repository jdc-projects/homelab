# Curated PrometheusRules for K3s.
#
# Rule files in rules/ are extracted from kube-prometheus-stack (same version
# as pinned in terraform/prometheus-operator/) with job="kubelet" label fixes
# applied where needed. They reference metrics collected via the ScrapeConfigs
# in scrapeconfigs.tf.
#
# The following chart rule files are deliberately excluded:
#   kube-apiserver-burnrate.rules     14 recording rules for multi-window SLO
#                                     burn rates (5m-3d). Production SLO
#                                     tracking - overkill for homelab.
#   kube-apiserver-slos               KubeAPIErrorBudgetBurn alerts. Depends
#                                     on burnrate rules above.
#   kubernetes-system-controller-manager  KubeControllerManagerDown + instance
#                                     unreachable. False positive - component
#                                     is bundled into the K3s process.
#   kubernetes-system-kube-proxy      KubeProxyDown + unreachable. Same.
#   kubernetes-system-scheduler       KubeSchedulerDown + unreachable. Same.
#
# To update: re-render the chart, diff against existing files, and replace.

locals {
  prometheus_rule_files = fileset("${path.module}/rules", "*.yaml")
}

resource "kubernetes_manifest" "prometheus_rule" {
  for_each = local.prometheus_rule_files

  manifest = merge(
    yamldecode(file("${path.module}/rules/${each.value}")),
    {
      metadata = merge(
        yamldecode(file("${path.module}/rules/${each.value}")).metadata,
        { namespace = kubernetes_namespace.prometheus.metadata[0].name }
      )
    }
  )

  depends_on = [helm_release.kube_prometheus_stack]
}
