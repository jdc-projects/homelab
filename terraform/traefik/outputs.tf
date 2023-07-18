output "merged_values" {
  value     = helm_release.traefik.metadata[0].values
  sensitive = true
}