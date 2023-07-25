output "namespace" {
    description = "Namespace for Loki."
    value = kubernetes_namespace.loki.metadata[0].name
}

output "gateway_username" {
    description = "Username to authenticate with the Loki gateway."
    value = random_password.gateway_username.result
}

output "gateway_password" {
    description = "Password to authenticate with the Loki gateway."
    value = random_password.gateway_password.result
}
