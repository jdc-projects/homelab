# Curated PrometheusRules for K3s.
#
# The kube-prometheus-stack chart's rules assume a standard kubeadm cluster
# where each control plane component (apiserver, controller-manager, scheduler,
# kube-proxy) runs as a separate pod with its own Service+ServiceMonitor. On
# K3s these are bundled into one process - the chart's per-component rules
# (9 PrometheusRule files) are false positives and are excluded here.
#
# The 26 rule files in rules/ are extracted from kube-prometheus-stack v88.1.2
# via helm template. They reference job="kubelet" with metrics_path="/metrics"
# which matches our ScrapeConfig configuration. To update: re-render the chart,
# diff against the existing files, and replace.

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
