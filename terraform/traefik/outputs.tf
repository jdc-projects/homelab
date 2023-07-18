output "merged_values" {
  value     = helm_release.traefik.metadata.values
  sensitive = true
}