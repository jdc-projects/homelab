output "namespace" {
  value       = kubernetes_namespace.oauth2_proxy.metadata[0].name
  description = "Namespace that oauth2-proxy is in."
}

output "service_name" {
  value       = helm_release.oauth2_proxy.name
  description = "Name of the service."
}

output "headers_middleware_name" {
  value       = kubernetes_manifest.oauth2_proxy_headers_middleware.manifest["metadata"].name
  description = "Name of the headers middleware."
}

output "redirect_middleware_name" {
  value       = kubernetes_manifest.oauth2_proxy_redirect_middleware.manifest["metadata"].name
  description = "Name of the middleware for the redirect version of the auth middleware."
}
