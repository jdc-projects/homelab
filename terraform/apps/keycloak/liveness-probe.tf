resource "kubernetes_config_map" "wait_for_keycloak_configmap" {
  metadata {
    name      = "wait_for_keycloak"
    namespace = kubernetes_namespace.keycloak_namespace.metadata[0].name
  }

  data = {
    url = "https://${null_resource.keycloak_domain.triggers.keycloak_domain}"
    responseCode = "200"
    timeout = "300000"
    interval = "200"
  }
}

resource "kubernetes_job" "wait_for_keycloak" {
  metadata {
    name      = "wait_for_keycloak"
    namespace = kubernetes_namespace.keycloak_namespace.metadata[0].name
  }

  spec {
    completions = 1

    template {
      metadata {
        name      = "wait_for_keycloak"
        namespace = kubernetes_namespace.keycloak_namespace.metadata[0].name
      }

      spec {
        container {
          name  = "wait_for_response"
          image = "nev7n/wait_for_response:latest"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.wait_for_keycloak_configmap
            }
          }
        }

        restart_policy = "Never"
      }
    }
  }

  wait_for_completion = true

  depends_on = [ helm_release.keycloak ]
}
