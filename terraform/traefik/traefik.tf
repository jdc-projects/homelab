resource "null_resource" "traefik_version" {
  triggers = {
    traefik_version = "28.2.0"
  }
}

resource "helm_release" "traefik" {
  name = "traefik"

  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = null_resource.traefik_version.triggers.traefik_version

  namespace = kubernetes_namespace.traefik.metadata[0].name

  timeout = 300

  set {
    name  = "logs.general.level"
    value = "INFO"
  }

  # hack for acme.json permissions problem
  set {
    name  = "deployment.initContainers[0].name"
    value = "volume-permissions"
  }
  set {
    name  = "deployment.initContainers[0].image"
    value = "busybox:1.36.1"
  }
  set {
    name  = "deployment.initContainers[0].command[0]"
    value = "sh"
  }
  set {
    name  = "deployment.initContainers[0].command[1]"
    value = "-c"
  }
  set {
    name  = "deployment.initContainers[0].command[2]"
    value = "touch /data/acme.json; chmod -v 600 /data/acme.json; chown -R 65532:65532 /data"
  }
  set {
    name  = "deployment.initContainers[0].securityContext.runAsNonRoot"
    value = "false"
  }
  set {
    name  = "deployment.initContainers[0].securityContext.runAsGroup"
    value = "0"
  }
  set {
    name  = "deployment.initContainers[0].securityContext.runAsUser"
    value = "0"
  }
  set {
    name  = "deployment.initContainers[0].volumeMounts[0].name"
    value = "data"
  }
  set {
    name  = "deployment.initContainers[0].volumeMounts[0].mountPath"
    value = "/data"
  }
  # end of hack

  set {
    name  = "providers.kubernetesCRD.allowCrossNamespace"
    value = "true"
  }
  set {
    name  = "providers.kubernetesCRD.allowExternalNameServices"
    value = "true"
  }
  set {
    name  = "providers.kubernetesIngress.allowExternalNameServices"
    value = "true"
  }

  set {
    name  = "metrics.prometheus"
    value = "null"
  }
  set {
    name  = "metrics.service.enabled"
    value = "false"
  }
  set {
    name  = "metrics.service.labels"
    value = "{}"
  }
  set {
    name  = "metrics.service.annotations"
    value = "{}"
  }
  set {
    name  = "metrics.disableAPICheck"
    value = "false"
  }
  set_list {
    name = "metrics.serviceMonitor.metricRelabelings"
    value = [
      <<-EOF
        sourceLabels: [__name__]
        separator: ;
        regex: ^fluentd_output_status_buffer_(oldest|newest)_.+
        replacement: $1
        action: drop
      EOF
      ,
    ]
  }
  set_list {
    name = "metrics.serviceMonitor.relabelings"
    value = [
      <<-EOF
        sourceLabels: [__meta_kubernetes_pod_node_name]
        separator: ;
        regex: ^(.*)$
        targetLabel: nodename
        replacement: $1
        action: replace
      EOF
      ,
    ]
  }
  set {
    name  = "metrics.serviceMonitor.jobLabel"
    value = "traefik"
  }
  set {
    name  = "metrics.serviceMonitor.interval"
    value = "30s"
  }
  set {
    name  = "metrics.serviceMonitor.honorLabels"
    value = "true"
  }
  set {
    name  = "metrics.prometheusRule.additionalLabels"
    value = "{}"
  }
  set {
    name  = "metrics.prometheusRule.namespace"
    value = kubernetes_namespace.traefik.metadata[0].name
  }
  set_list {
    name = "metrics.prometheusRule.rules"
    value = [
      <<-EOF
        alert: TraefikDown
        expr: up{job="traefik"} == 0
        for: 5m
        labels:
          context: traefik
          severity: warning
        annotations:
          summary: "Traefik Down"
          description: "{{ $labels.pod }} on {{ $labels.nodename }} is down"
      EOF
      ,
    ]
  }

  set {
    name  = "additionalArguments[0]"
    value = "--serverstransport.insecureskipverify=true"
  }

  set {
    name  = "ports.traefik.expose.default"
    value = "true"
  }

  set {
    name  = "ports.web.redirectTo.port"
    value = "websecure"
  }

  set {
    name  = "ports.websecure.tls.certResolver"
    value = "letsencrypt"
  }
  set {
    name  = "ports.websecure.tls.domains[0].main"
    value = var.server_base_domain
  }
  set {
    name  = "ports.websecure.tls.domains[0].sans[0]"
    value = "*.${var.server_base_domain}"
  }

  set {
    name  = "ports.ldaps.port"
    value = "8636"
  }
  set {
    name  = "ports.ldaps.expose.default"
    value = "true"
  }
  set {
    name  = "ports.ldaps.exposedPort"
    value = "636"
  }
  set {
    name  = "ports.ldaps.protocol"
    value = "TCP"
  }
  set {
    name  = "ports.ldaps.http3.enabled"
    value = "false"
  }

  set {
    name  = "tlsStore.default.defaultGeneratedCert.resolver"
    value = "letsencrypt"
  }
  set {
    name  = "tlsStore.default.defaultGeneratedCert.domain.main"
    value = var.server_base_domain
  }
  set {
    name  = "tlsStore.default.defaultGeneratedCert.domain.sans[0]"
    value = "*.${var.server_base_domain}"
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }
  set {
    name  = "persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.traefik.metadata[0].name
  }

  set {
    name  = "certResolvers.letsencrypt.email"
    value = "jack.chapman@sky.com"
  }
  set {
    name  = "certResolvers.letsencrypt.caServer"
    value = "https://acme-v02.api.letsencrypt.org/directory"
    # value = "https://acme-staging-v02.api.letsencrypt.org/directory"
  }
  set {
    name  = "certResolvers.letsencrypt.dnsChallenge.provider"
    value = "cloudflare"
  }
  set {
    name  = "env[0].name"
    value = "CF_DNS_API_TOKEN"
  }
  set_sensitive {
    name  = "env[0].value"
    value = var.cloudflare_acme_token
  }
  set {
    name  = "certResolvers.letsencrypt.dnsChallenge.delayBeforeCheck"
    value = "30"
  }
  set {
    name  = "certResolvers.letsencrypt.dnsChallenge.resolvers[0]"
    value = "sonia.ns.cloudflare.com"
  }
  set {
    name  = "certResolvers.letsencrypt.dnsChallenge.resolvers[1]"
    value = "sonny.ns.cloudflare.com"
  }
  set {
    name  = "certResolvers.letsencrypt.storage"
    value = "/data/acme.json"
  }

  lifecycle {
    replace_triggered_by  = [null_resource.traefik_version]
    create_before_destroy = false
  }
}

resource "null_resource" "traefik_cert_check" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "timeout 300 bash -c 'while ! curl -sI https://ping.${var.server_base_domain}; do echo \"Waiting for valid HTTPS cert\" && sleep 1; done'"
  }

  depends_on = [helm_release.traefik]
}
