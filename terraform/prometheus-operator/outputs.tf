output "grafana_admin_username" {
  value     = "admin"
  sensitive = true
}

output "grafana_admin_password" {
  value     = random_password.grafana_admin_password.result
  sensitive = true
}

output "grafana_url" {
  value = "https://${local.grafana_domain}"
}
