output "openbao_domain" {
  value = local.openbao_domain
}

output "openbao_url" {
  value = "https://${local.openbao_domain}"
}
