resource "kubernetes_namespace" "jdc_projects_runners_namespace" {
    metadata {
      name = "jdc-projects-runners"
    }
}

resource "helm_release" "jdc_projects_runners_controller" {
    name = "jdc-projects-runners-controller"

    repository = "https://actions-runner-controller.github.io/actions-runner-controller"
    chart = "actions-runner-controller"
    version = "v0.22.0"

    namespace = kubernetes_namespace.jdc_projects_runners_namespace.metadata[0].name

    set {
        name = "authSecret.create"
        value = "true"
    }
    set {
        name = "authSecret.github_app_id"
        value = var.jdc_projects_runners_app_id
    }
    set {
        name = "authSecret.github_app_installation_id"
        value = var.jdc_projects_runners_app_installation_id
    }
    set {
        name = "authSecret.github_app_private_key"
        value = var.jdc_projects_runners_app_private_key
    }

    set {
        name = "scope.singleNamespace"
        value = "true"
    }
    set {
        name = "scope.watchNamespace"
        value = kubernetes_namespace.jdc_projects_runners_namespace.metadata[0].name
    }

    set {
        name = "certManagerEnabled"
        value = "false"
    }

    set {
        name = "githubWebhookServer.enabled"
        value = "true"
    }
    set {
        name = "githubWebhookServer.secret.enabled"
        value = "true"
    }
    set {
        name = "githubWebhookServer.secret.create"
        value = "true"
    }
    set {
        name = "githubWebhookServer.secret.github_app_id"
        value = var.jdc_projects_runners_app_id
    }
    set {
        name = "githubWebhookServer.secret.github_app_installation_id"
        value = var.jdc_projects_runners_app_installation_id
    }
    set {
        name = "githubWebhookServer.secret.github_app_private_key"
        value = var.jdc_projects_runners_app_private_key
    }

    set {
        name = "githubWebhookServer.ingress.enabled"
        value = "true"
    }
    set {
        name = "githubWebhookServer.ingress.hosts[0].host"
        value = "github-jdc-projects-runners-webhook.jack-chapman.co.uk"
    }
    set {
        name = "githubWebhookServer.ingress.hosts[0].paths[0].path"
        value = "/"
    }
    set {
        name = "githubWebhookServer.ingress.hosts[0].paths[0].pathType"
        value = "ImplementationSpecific"
    }

    depends_on = [
      helm_release.traefik_ingress
    ]
}
