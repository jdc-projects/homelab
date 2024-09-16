resource "kubernetes_service" "internal" {
  count = local.is_endpoint_internal && !local.is_existing_service ? 1 : 0

  metadata {
    name      = "${var.name}-internal"
    namespace = var.namespace
  }

  spec {
    selector = var.selector

    port {
      port        = 80
      target_port = var.target_port
    }
  }
}

resource "kubernetes_service" "external" {
  count = local.is_endpoint_internal || local.is_existing_service ? 0 : 1

  metadata {
    name      = "${var.name}-external"
    namespace = var.namespace
  }

  spec {
    external_name = var.external_name
    type          = "ExternalName"
  }
}
