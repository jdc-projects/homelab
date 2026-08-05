output "traefik_api_key" {
  value     = random_password.traefik_api_key.result
  sensitive = true
}

output "crowdsec_namespace" {
  value = helm_release.crowdsec.name
}

output "crowdsec_helm_release_name" {
  value = helm_release.crowdsec.name
}
