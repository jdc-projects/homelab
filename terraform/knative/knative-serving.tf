resource "kubernetes_manifest" "knative_serving" {
  manifest = {
    apiVersion = "operator.knative.dev/v1beta1"
    kind = "KnativeServing"

    metadata = {
      name = "knative-serving"
      namespace = kubernetes_namespace.knative["serving"].metadata[0].name
    }

    spec = {
      version = "1.15.2"

      ingress = {
        istio = {
          enabled = false
        }
      }

      config = {
        network = {
          ingress-class = "gateway-api.ingress.networking.knative.dev"
        }
      }
    }
  }

  computed_fields = [
    "metadata.labels",
  ]
}
