resource "kubernetes_manifest" "deployment_hive_standalone_metastore" {
  manifest = {
    "apiVersion" = "apps/v1"
    "kind" = "Deployment"
    "metadata" = {
      "labels" = {
        "app" = "hsm"
      }
      "name" = "hive-standalone-metastore"
    }
    "spec" = {
      "replicas" = 1
      "selector" = {
        "matchLabels" = {
          "app" = "hsm"
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "app" = "hsm"
          }
        }
        "spec" = {
          "containers" = [
            {
              "env" = [
                {
                  "name" = "HIVE_METASTORE_URIS"
                  "value" = "thrift://0.0.0.0:9083"
                },
                {
                  "name" = "HIVE_DB_JDBC_URL"
                  "value" = ""
                },
                {
                  "name" = "HIVE_DB_DRIVER"
                  "value" = "org.postgresql.Driver"
                },
                {
                  "name" = "HIVE_DB_USER"
                  "value" = "postgres"
                },
                {
                  "name" = "HIVE_WAREHOUSE_DIR"
                  "value" = ""
                },
              ]
              "image" = "ghcr.io/binayakd/hive-standalone-metastore:4.0.0-hadoop-3.4.0"
              "name" = "hsm"
              "ports" = [
                {
                  "containerPort" = 9083
                },
              ]
            },
          ]
        }
      }
    }
  }
}
