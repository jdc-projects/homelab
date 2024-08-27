output "traefik_namespace" {
  value = kubernetes_namespace.traefik.metadata[0].name
}

output "traefik_helm_release_name" {
  value = helm_release.traefik.name
}
