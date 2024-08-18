output "github_org_runners_namespace_name" {
  value = kubernetes_namespace.github_org_runners.metadata[0].name
}
