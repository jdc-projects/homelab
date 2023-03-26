resource "kubernetes_deployment" "example" {
  metadata {
    name = "cloudflare_ddns"
    namespace = kubernetes_namespace.cloudflare_ddns_namespace.metadata[0].name
  }

  spec {
    replicas = 1

    template {
      spec {
        container {
          image = "nginx:1.21.6"
        }
      }
    }
  }
}
