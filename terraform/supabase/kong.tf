resource "kubernetes_config_map" "kong_env" {
  metadata {
    name      = "kong-env"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    KONG_DATABASE                      = "off"
    KONG_DECLARATIVE_CONFIG            = "/home/kong/kong.yml"
    KONG_DNS_ORDER                     = "LAST,A,CNAME"
    KONG_PLUGINS                       = "request-transformer,cors,key-auth,acl,basic-auth"
    KONG_NGINX_PROXY_PROXY_BUFFER_SIZE = "160k"
    KONG_NGINX_PROXY_PROXY_BUFFERS     = "64 160k"
  }
}

resource "kubernetes_secret" "kong_env" {
  metadata {
    name      = "kong-env"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    SUPABASE_ANON_KEY    = jwt_hashed_token.anon_key.token
    SUPABASE_SERVICE_KEY = jwt_hashed_token.service_key.token
    DASHBOARD_USERNAME   = random_password.dashboard_username.result
    DASHBOARD_PASSWORD   = random_password.dashboard_password.result
  }
}

resource "kubernetes_deployment" "kong" {
  metadata {
    name      = "kong"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = "supabase"
        component = "kong"
      }
    }

    template {
      metadata {
        labels = {
          app       = "supabase"
          component = "kong"
        }
      }

      spec {
        container {
          image = "kong:2.8.1"
          name  = "kong"

          command = ["bash -c 'eval \"echo \\\"$$(cat ~/temp.yml)\\\"\" > ~/kong.yml && /docker-entrypoint.sh kong docker-start'"]

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }

            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.kong_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.kong_env.metadata[0].name
            }
          }

          volume_mount {
            mount_path = "/home/kong"
            name       = "kong-yml"
            read_only  = true
          }
        }

        volume {
          name = "kong-yml"

          secret {
            secret_name = kubernetes_secret.kong_yml.metadata[0].name
          }
        }
      }
    }
  }

  timeouts {
    create = "5m"
    update = "5m"
    delete = "5m"
  }

  depends_on = [
    kubernetes_deployment.analytics
  ]
}

resource "kubernetes_service" "kong" {
  metadata {
    name      = "kong"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    selector = {
      app       = "supabase"
      component = "kong"
    }

    port {
      port        = 80
      target_port = 8000 # ***** 8443
    }
  }
}

resource "kubernetes_manifest" "kong_ingress" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "kong"
      namespace = kubernetes_namespace.supabase.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`supabase.${var.server_base_domain}`)"
        services = [{
          name      = kubernetes_service.kong.metadata[0].name
          namespace = kubernetes_namespace.supabase.metadata[0].name
          port      = kubernetes_service.kong.spec[0].port[0].port
        }]
      }]
    }
  }
}

resource "kubernetes_secret" "kong_yml" {
  metadata {
    name      = "kong-yml"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    # source: https://github.com/supabase/supabase/blob/v0.23.10/docker/volumes/api/kong.yml
    "temp.yml" = <<-EOF
      _format_version: '2.1'
      _transform: true

      ###
      ### Consumers / Users
      ###
      consumers:
        - username: DASHBOARD
        - username: anon
          keyauth_credentials:
            - key: ${jwt_hashed_token.anon_key.token}
        - username: service_role
          keyauth_credentials:
            - key: ${jwt_hashed_token.service_key.token}

      ###
      ### Access Control List
      ###
      acls:
        - consumer: anon
          group: anon
        - consumer: service_role
          group: admin

      ###
      ### Dashboard credentials
      ###
      basicauth_credentials:
      - consumer: DASHBOARD
        username: ${random_password.dashboard_username.result}
        password: ${random_password.dashboard_password.result}


      ###
      ### API Routes
      ###
      services:

        ## Open Auth routes
        - name: auth-v1-open
          url: http://auth:9999/verify
          routes:
            - name: auth-v1-open
              strip_path: true
              paths:
                - /auth/v1/verify
          plugins:
            - name: cors
        - name: auth-v1-open-callback
          url: http://auth:9999/callback
          routes:
            - name: auth-v1-open-callback
              strip_path: true
              paths:
                - /auth/v1/callback
          plugins:
            - name: cors
        - name: auth-v1-open-authorize
          url: http://auth:9999/authorize
          routes:
            - name: auth-v1-open-authorize
              strip_path: true
              paths:
                - /auth/v1/authorize
          plugins:
            - name: cors

        ## Secure Auth routes
        - name: auth-v1
          _comment: 'GoTrue: /auth/v1/* -> http://auth:9999/*'
          url: http://auth:9999/
          routes:
            - name: auth-v1-all
              strip_path: true
              paths:
                - /auth/v1/
          plugins:
            - name: cors
            - name: key-auth
              config:
                hide_credentials: false
            - name: acl
              config:
                hide_groups_header: true
                allow:
                  - admin
                  - anon

        ## Secure REST routes
        - name: rest-v1
          _comment: 'PostgREST: /rest/v1/* -> http://rest:3000/*'
          url: http://rest:3000/
          routes:
            - name: rest-v1-all
              strip_path: true
              paths:
                - /rest/v1/
          plugins:
            - name: cors
            - name: key-auth
              config:
                hide_credentials: true
            - name: acl
              config:
                hide_groups_header: true
                allow:
                  - admin
                  - anon

        ## Secure GraphQL routes
        - name: graphql-v1
          _comment: 'PostgREST: /graphql/v1/* -> http://rest:3000/rpc/graphql'
          url: http://rest:3000/rpc/graphql
          routes:
            - name: graphql-v1-all
              strip_path: true
              paths:
                - /graphql/v1
          plugins:
            - name: cors
            - name: key-auth
              config:
                hide_credentials: true
            - name: request-transformer
              config:
                add:
                  headers:
                    - Content-Profile:graphql_public
            - name: acl
              config:
                hide_groups_header: true
                allow:
                  - admin
                  - anon

        ## Secure Realtime routes
        - name: realtime-v1
          _comment: 'Realtime: /realtime/v1/* -> ws://realtime:4000/socket/*'
          url: http://realtime-dev.supabase-realtime:4000/socket/
          routes:
            - name: realtime-v1-all
              strip_path: true
              paths:
                - /realtime/v1/
          plugins:
            - name: cors
            - name: key-auth
              config:
                hide_credentials: false
            - name: acl
              config:
                hide_groups_header: true
                allow:
                  - admin
                  - anon

        ## Storage routes: the storage server manages its own auth
        - name: storage-v1
          _comment: 'Storage: /storage/v1/* -> http://storage:5000/*'
          url: http://storage:5000/
          routes:
            - name: storage-v1-all
              strip_path: true
              paths:
                - /storage/v1/
          plugins:
            - name: cors

        ## Edge Functions routes
        - name: functions-v1
          _comment: 'Edge Functions: /functions/v1/* -> http://functions:9000/*'
          url: http://functions:9000/
          routes:
            - name: functions-v1-all
              strip_path: true
              paths:
                - /functions/v1/
          plugins:
            - name: cors

        ## Analytics routes
        - name: analytics-v1
          _comment: 'Analytics: /analytics/v1/* -> http://logflare:4000/*'
          url: http://analytics:4000/
          routes:
            - name: analytics-v1-all
              strip_path: true
              paths:
                - /analytics/v1/

        ## Secure Database routes
        - name: meta
          _comment: 'pg-meta: /pg/* -> http://pg-meta:8080/*'
          url: http://meta:8080/
          routes:
            - name: meta-all
              strip_path: true
              paths:
                - /pg/
          plugins:
            - name: key-auth
              config:
                hide_credentials: false
            - name: acl
              config:
                hide_groups_header: true
                allow:
                  - admin

        ## Protected Dashboard - catch all remaining routes
        - name: dashboard
          _comment: 'Studio: /* -> http://studio:3000/*'
          url: http://studio:3000/
          routes:
            - name: dashboard-all
              strip_path: true
              paths:
                - /
          plugins:
            - name: cors
            - name: basic-auth
              config:
                hide_credentials: true
    EOF
  }
}
