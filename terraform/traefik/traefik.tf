resource "null_resource" "traefik_version" {
  triggers = {
    traefik_version = "31.1.1"
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
    value = "DEBUG"
  }

  set {
    name  = "deployment.kind"
    value = "DaemonSet"
  }

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
    value = "touch /data/acme.json; chmod -v 600 /data/acme.json; chown -R 0:0 /data"
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

  set {
    name  = "deployment.dnsPolicy"
    value = "ClusterFirstWithHostNet"
  }

  set {
    name  = "updateStrategy.rollingUpdate.maxUnavailable"
    value = "1"
  }
  set {
    name  = "updateStrategy.rollingUpdate.maxSurge"
    value = "0"
  }

  set {
    name  = "experimental.plugins.cloudflare-real-ip.moduleName"
    value = "github.com/BetterCorp/cloudflarewarp"
  }
  set {
    name  = "experimental.plugins.cloudflare-real-ip.version"
    value = "v1.3.0"
  }
  set {
    name  = "experimental.plugins.crowdsec-bouncer.moduleName"
    value = "github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin"
  }
  set {
    name  = "experimental.plugins.crowdsec-bouncer.version"
    value = "v1.3.3"
  }
  set {
    name  = "experimental.plugins.geoblock.moduleName"
    value = "github.com/PascalMinder/geoblock"
  }
  set {
    name  = "experimental.plugins.geoblock.version"
    value = "v0.2.8"
  }
  set {
    name  = "experimental.plugins.api-key-auth.moduleName"
    value = "github.com/dtomlinson91/traefik-api-key-middleware"
  }
  set {
    name  = "experimental.plugins.api-key-auth.version"
    value = "v0.1.2"
  }
  set {
    name  = "experimental.plugins.keycloak-auth.moduleName"
    value = "github.com/Gwojda/keycloakopenid"
  }
  set {
    name  = "experimental.plugins.keycloak-auth.version"
    value = "v0.1.35"
  }

  set {
    name  = "ingressRoute.dashboard.enabled"
    value = "true"
  }

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
    name  = "providers.kubernetesGateway.enabled"
    value = "true"
  }

  set {
    name  = "gateway.listeners.web.port"
    value = 80
  }
  set {
    name  = "gateway.listeners.web.namespacePolicy"
    value = "All"
  }
  set {
    name  = "gateway.listeners.websecure.port"
    value = 443
  }
  set {
    name  = "gateway.listeners.websecure.protocol"
    value = "HTTPS"
  }
  set {
    name  = "gateway.listeners.websecure.namespacePolicy"
    value = "All"
  }
  set {
    name  = "gateway.listeners.websecure.certificateRefs[0].name"
    value = kubernetes_manifest.cert_manager_certificate_wilcard.manifest.spec.secretName
  }
  set {
    name  = "gateway.listeners.websecure.mode"
    value = "Terminate"
  }

  set {
    name  = "additionalArguments[0]"
    value = "--serverstransport.insecureskipverify=true"
  }

  set {
    name  = "ports.traefik.port"
    value = 9000
  }

  set {
    name  = "ports.web.port"
    value = 80
  }
  set {
    name  = "ports.web.redirectTo.port"
    value = "websecure"
  }
  set {
    name  = "ports.web.redirectTo.permanent"
    value = "true"
  }

  set {
    name  = "ports.websecure.port"
    value = 443
  }

  set {
    name  = "ports.ldaps.port"
    value = 636
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
    name  = "ports.metrics.port"
    value = 9500
  }

  set {
    name  = "tlsStore.default.defaultCertificate.secretName"
    value = kubernetes_manifest.cert_manager_certificate_wilcard.manifest.spec.secretName
  }

  set {
    name  = "service.enabled"
    value = "false"
  }

  set {
    name  = "hostNetwork"
    value = "true"
  }

  set_list {
    name = "securityContext.capabilities.drop"
    value = [
      "ALL"
    ]
  }
  set_list {
    name = "securityContext.capabilities.add"
    value = [
      "NET_BIND_SERVICE"
    ]
  }
  set {
    name  = "securityContext.readOnlyRootFilesystem"
    value = "true"
  }
  set {
    name  = "securityContext.runAsGroup"
    value = "0"
  }
  set {
    name  = "securityContext.runAsNonRoot"
    value = "false"
  }
  set {
    name  = "securityContext.runAsUser"
    value = "0"
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
