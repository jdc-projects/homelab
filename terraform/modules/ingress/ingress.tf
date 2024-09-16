resource "kubernetes_manifest" "internal_ingress" {
  count = local.is_endpoint_internal ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "${var.name}-internal"
      namespace = var.namespace
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`${var.domain}`)${"" != var.path ? " && PathPrefix(`/${var.path}`)" : ""}"

        priority = var.priority

        services = [{
          name      = local.is_existing_service ? var.existing_service_name : one(kubernetes_service.internal[*].metadata[0].name)
          namespace = local.is_existing_service ? var.existing_service_namespace : var.namespace
          port      = local.is_existing_service ? var.target_port : one(kubernetes_service.internal[*].spec[0].port[0].port)
        }]

        middlewares = local.middlewares
      }]
    }
  }
}

resource "kubernetes_manifest" "external_ingress" {
  count = local.is_endpoint_internal && !local.is_existing_service ? 0 : 1

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "${var.name}-external"
      namespace = var.namespace
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`${var.domain}`)${"" != var.path ? " && PathPrefix(`/${var.path}`)" : ""}"

        priority = var.priority

        services = [{
          name      = one(kubernetes_service.external[*].metadata[0].name)
          namespace = var.namespace
          scheme    = var.is_external_scheme_http ? "http" : "https"
          port      = var.target_port
        }]

        middlewares = local.middlewares
      }]
    }
  }
}
