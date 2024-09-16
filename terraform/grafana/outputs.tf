output "grafana_labels" {
  value = kubernetes_manifest.grafana_deployment.manifest.metadata.labels
}
