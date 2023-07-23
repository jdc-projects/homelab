output "middleware_namespace" {
  type = "string"
  value = kubernetes_manifest.oauth2_proxy_headers_middleware.manifest["metadata"].namespace
  description = "Namespace that the middleware are in."
}

output "redirect_middleware_name" {
  type = "string"
  value = kubernetes_manifest.oauth2_proxy_redirect_middleware.manifest["metadata"].name
  description = "Name of the middleware for the redirect version of the auth middleware."
}
