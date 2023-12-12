resource "helm_release" "postgres_operator_ui" {
  name      = "stackgres"
  namespace = kubernetes_namespace.stackgres.metadata[0].name

  repository = "https://stackgres.io/downloads/stackgres-k8s/stackgres/helm/"
  chart      = "stackgres-operator"
  version    = "1.6.1"

  timeout = 300

  set_sensitive {
    name  = "authentication.user"
    value = random_password.admin_username.result
  }
  set_sensitive {
    name  = "authentication.password"
    value = random_password.admin_password.result
  }

  # set {
  #   name  = ""
  #   value = ""
  # }

  # set {
  #   name  = ""
  #   value = ""
  # }
}