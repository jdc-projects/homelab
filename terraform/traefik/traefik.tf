resource "null_resource" "traefik_version" {
  triggers = {
    traefik_version = "37.4.0"
  }
}

resource "helm_release" "traefik" {
  name = "traefik"

  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = null_resource.traefik_version.triggers.traefik_version

  namespace = kubernetes_namespace.traefik.metadata[0].name

  timeout = 300

  set = [
    {
      name  = "logs.general.level"
      value = "DEBUG"
    },
    {
      name  = "deployment.kind"
      value = "DaemonSet"
    },
    {
      name  = "deployment.dnsPolicy"
      value = "ClusterFirstWithHostNet"
    },
    {
      name  = "updateStrategy.rollingUpdate.maxUnavailable"
      value = "1"
    },
    {
      name  = "updateStrategy.rollingUpdate.maxSurge"
      value = "0"
    },
    {
      name  = "experimental.plugins.cloudflare.moduleName"
      value = "https://github.com/agence-gaya/traefik-plugin-cloudflare"
    },
    {
      name  = "experimental.plugins.cloudflare.version"
      value = "v1.2.0"
    },
    {
      name  = "experimental.plugins.cloudflare-real-ip.moduleName"
      value = "github.com/BetterCorp/cloudflarewarp"
    },
    {
      name  = "experimental.plugins.cloudflare-real-ip.version"
      value = "v1.3.3"
    },
    {
      name  = "experimental.plugins.crowdsec-bouncer.moduleName"
      value = "github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin"
    },
    {
      name  = "experimental.plugins.crowdsec-bouncer.version"
      value = "v1.3.5"
    },
    {
      name  = "experimental.plugins.geoblock.moduleName"
      value = "github.com/PascalMinder/geoblock"
    },
    {
      name  = "experimental.plugins.geoblock.version"
      value = "v0.3.1"
    },
    {
      name  = "experimental.plugins.api-key-auth.moduleName"
      value = "github.com/dtomlinson91/traefik-api-key-middleware"
    },
    {
      name  = "experimental.plugins.api-key-auth.version"
      value = "v0.1.2"
    },
    {
      name  = "experimental.plugins.keycloak-auth.moduleName"
      value = "github.com/Gwojda/keycloakopenid"
    },
    {
      name  = "experimental.plugins.keycloak-auth.version"
      value = "v0.1.35"
    },
    {
      name  = "ingressRoute.dashboard.enabled"
      value = "true"
    },
    {
      name  = "providers.kubernetesCRD.allowCrossNamespace"
      value = "true"
    },
    {
      name  = "providers.kubernetesCRD.allowExternalNameServices"
      value = "true"
    },
    {
      name  = "providers.kubernetesIngress.allowExternalNameServices"
      value = "true"
    },
    {
      name  = "providers.kubernetesGateway.enabled"
      value = "true"
    },
    {
      name  = "gateway.listeners.web.port"
      value = 80
    },
    {
      name  = "gateway.listeners.websecure.port"
      value = 443
    },
    {
      name  = "gateway.listeners.websecure.protocol"
      value = "HTTPS"
    },
    {
      name  = "gateway.listeners.websecure.namespacePolicy.from"
      value = "All"
    },
    {
      name  = "gateway.listeners.websecure.certificateRefs[0].name"
      value = kubernetes_manifest.cert_manager_certificate_wilcard.manifest.spec.secretName
    },
    {
      name  = "gateway.listeners.websecure.mode"
      value = "Terminate"
    },
    {
      name  = "additionalArguments[0]"
      value = "--serverstransport.insecureskipverify=true"
    },
    {
      name  = "ports.traefik.port"
      value = 9000
    },
    {
      name  = "ports.web.port"
      value = 80
    },
    {
      name  = "ports.web.redirections.entryPoint.to"
      value = "websecure"
    },
    {
      name  = "ports.web.redirections.entryPoint.scheme"
      value = "https"
    },
    {
      name  = "ports.web.redirections.entryPoint.permanent"
      value = "true"
    },
    {
      name  = "ports.websecure.port"
      value = 443
    },
    {
      name  = "ports.ldaps.port"
      value = 636
    },
    {
      name  = "ports.ldaps.protocol"
      value = "TCP"
    },
    {
      name  = "ports.ldaps.http3.enabled"
      value = "false"
    },
    {
      name  = "ports.metrics.port"
      value = 9500
    },
    {
      name  = "tlsStore.default.defaultCertificate.secretName"
      value = kubernetes_manifest.cert_manager_certificate_wilcard.manifest.spec.secretName
    },
    {
      name  = "service.enabled"
      value = "false"
    },
    {
      name  = "hostNetwork"
      value = "true"
    },
    {
      name  = "securityContext.readOnlyRootFilesystem"
      value = "true"
    },
    {
      name  = "securityContext.runAsGroup"
      value = "0"
    },
    {
      name  = "securityContext.runAsNonRoot"
      value = "false"
    },
    {
      name  = "securityContext.runAsUser"
      value = "0"
    },
  ]

  set_list = [
    {
      name = "securityContext.capabilities.drop"
      value = [
        "ALL"
      ]
    },
    {
      name = "securityContext.capabilities.add"
      value = [
        "NET_BIND_SERVICE"
      ]
    },
  ]

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
