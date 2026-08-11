#!/usr/bin/env sh
# helm post-renderer for the huly chart.
#
# Reads helm-rendered YAML on stdin, writes patched YAML on stdout. Two
# patches, both working around chart limitations (verified against chart
# version 0.1.0):
#
#   1. URL scheme rewrite in the chart's ConfigMap.
#      The chart's configmap.yaml derives the URL scheme (http/https, ws/wss)
#      for browser-facing URLs from `ingress.enabled && ingress.tls.enabled`.
#      We set ingress.enabled=false (we use modules/ingress, not chart-managed
#      ingress), so the chart produces http:// and ws:// URLs - which browsers
#      refuse from an https page (mixed content). Rewrite only the URLs that
#      contain our public domain; internal pod-to-pod URLs (http://account:3000
#      etc.) are left untouched.
#
#   2. OTel injection annotation on every chart-rendered Deployment.
#      The chart's deployment templates don't expose a pod-annotations hook,
#      so we can't add `instrumentation.opentelemetry.io/inject-nodejs` via
#      values. The opentelemetry-operator picks it up and injects the Node.js
#      SDK + exporter env vars at admission time.
#
# Argument: $1 = the huly domain (e.g. huly.example.com).
#
# Robustness: both patches are pattern-based (look for the ConfigMap by name,
# Deployments by kind). If a future chart version renames the ConfigMap or
# restructures Deployments, the patches silently no-op rather than crash;
# add a regression check after chart version bumps.

set -eu

DOMAIN="${1:?usage: post-renderer.sh <huly-domain>}"

exec yq eval-all --prettyPrint '
  (
    select(.kind == "ConfigMap" and .metadata.name == "huly-config").data // {}
  ) |= with_entries(
    .value |= (
      sub("http://'"$DOMAIN"'", "https://'"$DOMAIN"'") |
      sub("ws://'"$DOMAIN"'", "wss://'"$DOMAIN"'")
    )
  ),
  select(.kind == "Deployment").spec.template.metadata.annotations["instrumentation.opentelemetry.io/inject-nodejs"] = "true"
'
