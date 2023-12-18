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

output "grafana_oauth_client_id" {
  value = local.oauth_client_id
}

output "grafana_oauth_client_secret" {
  value     = random_password.oauth_client_secret.result
  sensitive = true
}

output "oauth_domain" {
  value = local.oauth_domain
}

output "oauth_realm_name" {
  value = local.oauth_realm_name
}

output "oauth_url_base" {
  value = local.oauth_url_base
}

output "oauth_auth_url" {
  value = local.oauth_auth_url
}

output "oauth_token_url" {
  value = local.oauth_token_url
}

output "oauth_api_url" {
  value = local.oauth_api_url
}

output "grafana_oauth_admin_role_name" {
  value = local.oauth_admin_role_name
}
