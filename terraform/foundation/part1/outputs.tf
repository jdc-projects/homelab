output "jdc_projects_runners_namespace_name" {
  value = kubernetes_namespace.jdc_projects_runners_namespace.metadata[0].name
}
