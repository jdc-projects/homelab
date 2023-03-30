resource "kubernetes_namespace" "traefik_namespace" {
  metadata {
    name = "traefik"
  }
}

resource "kubernetes_persistent_volume_claim" "traefik_pvc" {
  metadata {
    name      = "treafik-pvc"
    namespace = kubernetes_namespace.traefik_namespace.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "128Mi"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "helm_release" "traefik_ingress" {
  name = "traefik"

  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = "v21.2.0"

  namespace = kubernetes_namespace.traefik_namespace.metadata[0].name

  # hack for acme.json permissions problem
  set {
    name  = "deployment.initContainers[0].name"
    value = "volume-permissions"
  }
  set {
    name  = "deployment.initContainers[0].image"
    value = "busybox:1.35.0"
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
    value = "touch /data/acme.json; chmod -v 600 /data/acme.json"
  }
  set {
    name  = "deployment.initContainers[0].securityContext.runAsNonRoot"
    value = "true"
  }
  set {
    name  = "deployment.initContainers[0].securityContext.runAsGroup"
    value = "65532"
  }
  set {
    name  = "deployment.initContainers[0].securityContext.runAsUser"
    value = "65532"
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
    name  = "ports.traefik.expose"
    value = "true"
  }

  set {
    name  = "ports.web.redirectTo"
    value = "websecure"
  }

  set {
    name  = "ports.websecure.tls.certResolver"
    value = "letsencrypt"
  }
  set {
    name  = "ports.websecure.tls.domains[0].main"
    value = "${var.server_base_domain}"
  }
  set {
    name  = "ports.websecure.tls.domains[0].sans[0]"
    value = "*.${var.server_base_domain}"
  }

  set {
    name  = "additionalArguments[0]"
    value = "--providers.kubernetesingress.allowexternalnameservices"
  }
  set {
    name  = "additionalArguments[1]"
    value = "--providers.kubernetescrd.allowexternalnameservices"
  }
  set {
    name  = "additionalArguments[0]"
    value = "--serverstransport.insecureskipverify=true"
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }
  set {
    name  = "persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.traefik_pvc.metadata[0].name
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
}
