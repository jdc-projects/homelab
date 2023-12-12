resource "helm_release" "stackgres" {
  name      = "stackgres"
  namespace = kubernetes_namespace.stackgres.metadata[0].name

  repository = "https://stackgres.io/downloads/stackgres-k8s/stackgres/helm/"
  chart      = "stackgres-operator"
  version    = "1.6.1"

  timeout = 300

  set {
    name  = "adminui.service.exposeHTTP"
    value = "true"
  }

  set_sensitive {
    name  = "authentication.password"
    value = random_password.admin_password.result
  }

  # prometheus operator not setup
  set {
    name  = "prometheus.allowAutobind"
    value = "false"
  }
}

# module "postgres_operator_ui_ingress" {
#   source = "../modules/auth-ingress"

#   server_base_domain = var.server_base_domain
#   namespace          = kubernetes_namespace.stackgres.metadata[0].name
#   service_name       = helm_release.stackgres.name
#   service_port       = 443
#   url_subdomain      = "postgres"
# }

# resource "kubernetes_manifest" "headers" {
#   manifest = {
#     apiVersion = "traefik.io/v1alpha1"
#     kind       = "Middleware"

#     metadata = {
#       name      = "headers"
#       namespace = kubernetes_namespace.stackgres.metadata[0].name
#     }

#     spec = {
#       headers = {
#         sslProxyHeaders = {
#           "X-Forwarded-Proto" = "https",
#         }
#       }
#     }
#   }
# }

# ***** temporary
resource "kubernetes_manifest" "ingress" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "ingress"
      namespace = kubernetes_namespace.stackgres.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        priority = "20"
        match = "Host(`postgres.${var.server_base_domain}`)"
        services = [{
          name      = "${helm_release.stackgres.name}-restapi"
          namespace = kubernetes_namespace.stackgres.metadata[0].name
          port      = 80
        }]
        # middlewares = [{
        #   name      = kubernetes_manifest.headers.manifest.metadata.name
        #   namespace = kubernetes_namespace.stackgres.metadata[0].name
        # }]
      }]
    }
  }
}

# resource "kubernetes_manifest" "ingress2" {
#   manifest = {
#     apiVersion = "traefik.io/v1alpha1"
#     kind       = "IngressRoute"

#     metadata = {
#       name      = "ingress2"
#       namespace = kubernetes_namespace.stackgres.metadata[0].name
#     }

#     spec = {
#       entryPoints = ["websecure"]

#       routes = [{
#         kind  = "Rule"
#         priority = "10"
#         match = "Host(`postgres.${var.server_base_domain}`) && Path(`/grafana`)"
#         services = [{
#           name      = "${helm_release.stackgres.name}"
#           namespace = kubernetes_namespace.stackgres.metadata[0].name
#           port      = 443
#         }]
#       }]
#     }
#   }
# }
