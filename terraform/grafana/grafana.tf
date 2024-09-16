locals {
  grafana_domain  = "grafana.${var.server_base_domain}"
  grafana_version = "11.1.5"
}

resource "kubernetes_manifest" "grafana_deployment" {
  manifest = {
    apiVersion = "grafana.integreatly.org/v1beta1"
    kind       = "Grafana"

    metadata = {
      name      = "grafana"
      namespace = kubernetes_namespace.grafana.metadata[0].name

      labels = {
        dashboards = "grafana"
      }
    }

    spec = {
      version = local.grafana_version

      config = {
        log = {
          mode = "console"
        }

        server = {
          root_url = "https://${local.grafana_domain}"
        }

        users = {
          viewers_can_edit = "true"
        }

        auth = {
          disable_login_form = "false"
        }

        "auth.generic_oauth" = {
          enabled               = "true"
          name                  = "Keycloak"
          allow_sign_up         = "true"
          client_id             = keycloak_openid_client.grafana.client_id
          client_secret         = random_password.keycloak_client_secret.result
          scopes                = "openid"
          email_attribute_path  = "email"
          login_attribute_path  = "preferred_username"
          name_attribute_path   = "full_name"
          groups_attribute_path = "groups"
          auth_url              = data.terraform_remote_state.keycloak.outputs.keycloak_auth_url
          token_url             = data.terraform_remote_state.keycloak.outputs.keycloak_token_url
          api_url               = data.terraform_remote_state.keycloak.outputs.keycloak_api_url
          role_attribute_path   = "contains(roles[*]\\, '${keycloak_role.grafana_admin.name}') && 'GrafanaAdmin'"
          auto_login            = "true"
        }
      }
    }
  }

  wait {
    fields = {
      "status.stage"       = "complete"
      "status.stageStatus" = "success"
      "status.version"     = local.grafana_version
    }
  }
}
