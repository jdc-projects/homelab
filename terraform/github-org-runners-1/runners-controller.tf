resource "helm_release" "githib_org_runners_controller" {
  name = "github-org-runners-controller"

  repository = "https://actions-runner-controller.github.io/actions-runner-controller"
  chart      = "actions-runner-controller"
  version    = "v0.23.3"

  namespace = kubernetes_namespace.github_org_runners.metadata[0].name

  timeout = 300

  set {
    name  = "authSecret.create"
    value = "true"
  }
  set {
    name  = "authSecret.github_app_id"
    value = var.jdc_projects_runners_app_id
  }
  set {
    name  = "authSecret.github_app_installation_id"
    value = var.jdc_projects_runners_app_installation_id
  }
  set_sensitive {
    name  = "authSecret.github_app_private_key"
    value = var.jdc_projects_runners_app_private_key
  }

  set {
    name  = "image.dindSidecarRepositoryAndTag"
    value = "docker:24.0.2-dind"
  }

  set {
    name  = "scope.singleNamespace"
    value = "true"
  }
  set {
    name  = "scope.watchNamespace"
    value = kubernetes_namespace.github_org_runners.metadata[0].name
  }

  set {
    name  = "certManagerEnabled"
    value = "false"
  }

  set {
    name  = "githubWebhookServer.enabled"
    value = "true"
  }
  set {
    name  = "githubWebhookServer.secret.enabled"
    value = "true"
  }
  set {
    name  = "githubWebhookServer.secret.create"
    value = "true"
  }
  set {
    name  = "githubWebhookServer.secret.github_app_id"
    value = var.jdc_projects_runners_app_id
  }
  set {
    name  = "githubWebhookServer.secret.github_app_installation_id"
    value = var.jdc_projects_runners_app_installation_id
  }
  set_sensitive {
    name  = "githubWebhookServer.secret.github_app_private_key"
    value = var.jdc_projects_runners_app_private_key
  }

  set {
    name  = "githubWebhookServer.ingress.enabled"
    value = "true"
  }
  set {
    name  = "githubWebhookServer.ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.entrypoints"
    value = "websecure"
  }
  set {
    name  = "githubWebhookServer.ingress.hosts[0].host"
    value = "github-jdc-projects-runners-webhook.${var.server_base_domain}"
  }
  set {
    name  = "githubWebhookServer.ingress.hosts[0].paths[0].path"
    value = "/"
  }
  set {
    name  = "githubWebhookServer.ingress.hosts[0].paths[0].pathType"
    value = "ImplementationSpecific"
  }
}
