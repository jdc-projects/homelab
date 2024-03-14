resource "kubernetes_config_map" "appflowy_db_init_scripts" {
  metadata {
    name      = "appflowy-db-init-scripts"
    namespace = kubernetes_namespace.appflowy.metadata[0].name
  }

  data = {
    # https://github.com/AppFlowy-IO/AppFlowy-Cloud/blob/main/migrations/before/20230312043000_supabase_auth.sql
    "20230312043000_supabase_auth.sql" = <<-EOF
      -- Add migration script here
      -- Create the anon and authenticated roles if they don't exist
      CREATE OR REPLACE FUNCTION create_roles(roles text []) RETURNS void LANGUAGE plpgsql AS $$
      DECLARE role_name text;
      BEGIN FOREACH role_name IN ARRAY roles LOOP IF NOT EXISTS (
          SELECT 1
          FROM pg_roles
          WHERE rolname = role_name
      ) THEN EXECUTE 'CREATE ROLE ' || role_name;
      END IF;
      END LOOP;
      END;
      $$;
      SELECT create_roles(ARRAY ['anon', 'authenticated']);

      -- Create supabase_admin user if it does not exist
      DO $$ BEGIN IF NOT EXISTS (
          SELECT
          FROM pg_catalog.pg_roles
          WHERE rolname = 'supabase_admin'
      ) THEN CREATE USER supabase_admin LOGIN CREATEROLE CREATEDB REPLICATION BYPASSRLS;
      END IF;
      END $$;
      -- Create supabase_auth_admin user if it does not exist
      DO $$ BEGIN IF NOT EXISTS (
          SELECT
          FROM pg_catalog.pg_roles
          WHERE rolname = 'supabase_auth_admin'
      ) THEN CREATE USER supabase_auth_admin BYPASSRLS NOINHERIT CREATEROLE LOGIN NOREPLICATION PASSWORD 'root'; -- ***** this looks like an exposed password...
      END IF;
      END $$;
      -- Create auth schema if it does not exist
      CREATE SCHEMA IF NOT EXISTS auth AUTHORIZATION supabase_auth_admin;
      -- Grant permissions
      GRANT CREATE ON DATABASE postgres TO supabase_auth_admin;
      -- Set search_path for supabase_auth_admin
      ALTER USER supabase_auth_admin SET search_path = 'auth';
    EOF
  }
}

resource "kubernetes_manifest" "appflowy_db" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"

    metadata = {
      name      = "appflowy-db"
      namespace = kubernetes_namespace.appflowy.metadata[0].name

      labels = {
        "velero.io/exclude-from-backup" = "true"
      }

      annotations = {
        "cnpg.io/hibernation" = var.is_db_hibernate ? "on" : "off"
      }
    }

    spec = {
      # https://github.com/cloudnative-pg/postgres-containers/pkgs/container/postgresql
      imageName = "ghcr.io/cloudnative-pg/postgresql:16.1-16"

      instances = local.appflowy_db_instances

      postgresql = {
        parameters = {
          shared_buffers = "256MB"
        }
      }

      bootstrap = {
        initdb = {
          database = "appflowy"
          owner    = random_password.appflowy_db_username.result
          secret = {
            name = kubernetes_secret.db_credentials.metadata[0].name
          }

          postInitApplicationSQLRefs = {
            configMapRefs = [{
              name = kubernetes_config_map.appflowy_db_init_scripts.metadata[0].name
              key  = "20230312043000_supabase_auth.sql"
            }]
          }
        }
      }

      storage = {
        storageClass = "openebs-zfs-localpv-random"
        size         = "5Gi"

        pvcTemplate = {
          accessModes = [
            "ReadWriteOnce",
          ]
        }
      }

      resources = {
        requests = {
          cpu    = "500m"
          memory = "1Gi"
        }

        limits = {
          cpu    = "500m"
          memory = "1Gi"
        }
      }

      primaryUpdateStrategy = "unsupervised"
      primaryUpdateMethod   = "switchover"

      logLevel = "info"
    }
  }

  computed_fields = [
    "metadata.labels",
    "metadata.annotations",
    "spec.postgresql.parameters",
  ]

  wait {
    fields = var.is_db_hibernate ? {
      "status.phase"                                           = "Cluster in healthy state"
      "status.danglingPVC[${local.appflowy_db_instances - 1}]" = "*"
      } : {
      "status.phase"                                          = "Cluster in healthy state"
      "status.readyInstances"                                 = local.appflowy_db_instances
      "status.healthyPVC[${local.appflowy_db_instances - 1}]" = "*"
    }
  }

  lifecycle {
    prevent_destroy = false # *****
  }
}
