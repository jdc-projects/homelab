# https://knative.dev/docs/install/operator/knative-with-operators/
#
# Knative Serving, reconciled by the Knative Operator. No spec.ingress.* enables
# a bundled ingress, so the operator installs ONLY the core Serving components
# (activator, autoscaler, controller, webhook). Traefik (with its Knative
# provider enabled, see iac/traefik) is the external ingress owning Tier-1
# routing for cluster-local and internal functions. Tier-2 (public + auth'd)
# functions are exposed via the shared ingress module pointing at the ksvc's
# service instead.

resource "kubernetes_manifest" "knative_serving" {
  manifest = {
    apiVersion = "operator.knative.dev/v1beta1"
    kind       = "KnativeServing"

    metadata = {
      name      = "knative-serving"
      namespace = kubernetes_namespace.knative_serving.metadata[0].name
    }

    spec = {
      version = local.knative_version

      # The operator enables the bundled Istio ingress plugin by default and
      # fails the install if Istio isn't present. We use Traefik's (external)
      # Knative provider instead, so disable Istio explicitly. No bundled
      # ingress controller is then installed; serving stamps its internal
      # Ingress resources with the class below and Traefik reconciles them.
      ingress = {
        istio = {
          enabled = false
        }
      }

      config = {
        network = {
          ingress-class = local.ingress_class
          # Auto-create ClusterDomainClaims so DomainMappings work without manual
          # claim resources. Required for the Tier-2 pattern (external domain →
          # DomainMapping → Kingress → knative entrypoint).
          "autocreate-cluster-domain-claims" = "true"
        }

        # Public services get <svc>.<namespace>.<server_base_domain>; services
        # labelled networking.knative.dev/visibility=cluster-local resolve as
        # <svc>.<namespace>.svc.cluster.local (in-cluster only, which is what the
        # Tier-2 ingress module points at).
        domain = {
          (var.server_base_domain) = ""
        }

        # Request + CloudEvent traces -> OTel collector (-> Tempo). Knative 1.22
        # moved tracing out of config-tracing (deprecated) into
        # config-observability; OTLP HTTP is a first-class backend.
        observability = {
          tracing-protocol = "http/protobuf"
          tracing-endpoint = "http://otel-collector.otel.svc:4318/v1/traces"
        }
      }
    }
  }

  computed_fields = [
    "metadata.labels",
    "metadata.annotations",
  ]

  depends_on = [null_resource.wait_for_operator_crds]
}
