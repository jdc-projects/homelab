output "ippool_cidr" {
  value       = "10.42.0.0/16"
  description = "The Calico IPPool CIDR (matches the k3s cluster-cidr)."
}

output "operator_namespace" {
  value       = "tigera-operator"
  description = "Namespace the tigera-operator runs in."
}

output "calico_namespace" {
  value       = "calico-system"
  description = "Namespace the operator deploys Calico components (calico-node, etc.) into."
}
