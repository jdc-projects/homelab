output "traefik_namespace" {
  value = kubernetes_namespace.traefik.metadata[0].name
}
