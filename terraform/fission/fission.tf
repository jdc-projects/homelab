locals {
  fission_version = "1.20.4"
}

resource "null_resource" "crd_updates" {
  triggers = {
    fission_version = local.fission_version
  }

  provisioner "local-exec" {
    when    = create
    command = <<-EOF
      curl -Lo fission.tar.gz https://github.com/fission/fission/archive/refs/tags/v${self.triggers.fission_version}.tar.gz
      mkdir ./fission
      tar -xzf fission.tar.gz -C fission
      cd ./fission/*/crds/v1
      rm kustomization.yaml
      kubectl apply --server-side --force-conflicts -f ./
    EOF
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      curl -Lo fission.tar.gz https://github.com/fission/fission/archive/refs/tags/v${self.triggers.fission_version}.tar.gz
      mkdir ./fission
      tar -xzf fission.tar.gz -C fission
      cd ./fission/*/crds/v1
      rm kustomization.yaml
      kubectl delete -f ./
    EOF
  }
}

resource "helm_release" "fission" {
  name = "fission"

  repository = "https://fission.github.io/fission-charts/"
  chart      = "fission-all"
  version    = local.fission_version

  namespace = kubernetes_namespace.fission["core"].metadata[0].name

  timeout = 300

  set {
    name  = "routerServiceType"
    value = "ClusterIP"
  }

  set {
    name  = "builderNamespace"
    value = kubernetes_namespace.fission["builder"].metadata[0].name
  }
  set {
    name  = "functionNamespace"
    value = kubernetes_namespace.fission["functions"].metadata[0].name
  }
  set_list {
    name = "additionalFissionNamespaces"
    value = [
      kubernetes_namespace.fission["environments"].metadata[0].name,
      kubernetes_namespace.fission["apps"].metadata[0].name,
    ]
  }

  set {
    name  = "createNamespace"
    value = "false"
  }

  set {
    name  = "persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.fission.metadata[0].name
  }

  depends_on = [
    null_resource.crd_updates,
  ]
}
