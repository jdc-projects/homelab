output "fission_environments_namespace" {
  value = kubernetes_namespace.fission["environments"].metadata[0].name
}
