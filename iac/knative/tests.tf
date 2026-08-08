locals {
  # Pre-built OCI image for the throwaway test functions. event_display logs
  # every received CloudEvent (verifies source delivery) AND answers plain HTTP
  # GETs, so it doubles as the Tier-2 responder for fn-public. (The classic
  # serving "default-sample"/"helloworld" images aren't reliably published under
  # gcr.io/knative-releases, so we reuse this one.)
  test_image_events = "gcr.io/knative-releases/knative.dev/eventing/cmd/event_display"
  test_image_http   = "gcr.io/knative-releases/knative.dev/eventing/cmd/event_display"

  # The knative-test namespace exists iff any test is enabled.
  test_ns = one(kubernetes_namespace.knative_test[*].metadata[0].name)
}

resource "kubernetes_namespace" "knative_test" {
  count = anytrue([for v in var.enable_tests : v]) ? 1 : 0

  metadata {
    name = "knative-test"

    # Lets the (cluster-wide) Knative Serving/Eventing controllers act on
    # objects here, and marks it for easy teardown.
    labels = {
      "homelab.jdc/knative-test" = "true"
    }
  }
}
