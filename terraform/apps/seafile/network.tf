resource "kubernetes_service" "seafile" {
  metadata {
    name      = "seafile"
    namespace = kubernetes_namespace.seafile.metadata[0].name
  }

  spec {
    selector = {
      app = "seafile"
    }

    port {
      port        = 8000
      target_port = 8000
    }
  }
}

resource "kubernetes_service" "seafile_fileserver" {
  metadata {
    name      = "seafile-fileserver"
    namespace = kubernetes_namespace.seafile.metadata[0].name
  }

  spec {
    selector = {
      app = "seafile"
    }

    port {
      port        = 8082
      target_port = 8082
    }
  }
}

resource "kubernetes_service" "seafile_notification" {
  metadata {
    name      = "seafile-notification"
    namespace = kubernetes_namespace.seafile.metadata[0].name
  }

  spec {
    selector = {
      app = "seafile"
    }

    port {
      port        = 8083
      target_port = 8083
    }
  }
}

resource "kubernetes_manifest" "seafile_ingress" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "seafile"
      namespace = kubernetes_namespace.seafile.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`seafile.${var.server_base_domain}`)"
        services = [{
          name      = kubernetes_service.seafile.metadata[0].name
          namespace = kubernetes_namespace.seafile.metadata[0].name
          port      = kubernetes_service.seafile.spec[0].port[0].port
        }]
      }]
    }
  }
}

resource "kubernetes_manifest" "seafile_fileserver_ingress" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "seafile-fileserver"
      namespace = kubernetes_namespace.seafile.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`seafile.${var.server_base_domain}`) && Path(`/seafhttp`)"
        services = [{
          name      = kubernetes_service.seafile_fileserver.metadata[0].name
          namespace = kubernetes_namespace.seafile.metadata[0].name
          port      = kubernetes_service.seafile_fileserver.spec[0].port[0].port
        }]
      }]
    }
  }
}

resource "kubernetes_manifest" "seafile_notification_ingress" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "seafile-notification"
      namespace = kubernetes_namespace.seafile.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`seafile.${var.server_base_domain}`) && Path(`/notification`)"
        services = [{
          name      = kubernetes_service.seafile_notification.metadata[0].name
          namespace = kubernetes_namespace.seafile.metadata[0].name
          port      = kubernetes_service.seafile_notification.spec[0].port[0].port
        }]
      }]
    }
  }
}
