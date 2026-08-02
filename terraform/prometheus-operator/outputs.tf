output "kube_prometheus_stack_version" {
  value       = local.kube_prometheus_stack_version
  description = "Pinned kube-prometheus-stack chart version. The terraform/prometheus/ instance module reads this via terraform_remote_state to stay in lock-step."
}

output "namespace" {
  value = kubernetes_namespace.prometheus_operator.metadata[0].name
}
