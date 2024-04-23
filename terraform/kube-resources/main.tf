locals {
  name   = "trino-on-eks"
  region = "ap-southeast-1"

  kube_namespace = "trino"
  kube_sa_name = "s3-access"

  tags = {
    role = "trino-on-eks"
  }
}

data "aws_eks_cluster" "default" {
  name = local.name
}

data "aws_eks_cluster_auth" "default" {
  name = local.name
}

data "aws_iam_role" "example" {
  name = "an_example_role_name"
}

data "aws_db_instance" "trino_on_eks_rds" {
  db_instance_identifier = local.name
}

data "aws_secretsmanager_secret" "rds_password" {
  name = "test-db-password"

}

data "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = data.aws_secretsmanager_secret.rds_password.id
}


provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.default.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.default.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.default.token
  }
}

resource "kubernetes_namespace" "name" {
  metadata {
    name = local.kube_namespace
  }
  
}

resource "kubernetes_service_account" "trino_s3_access_sa" {
  metadata {
    name = local.kube_sa_name
    namespace = local.kube_namespace

    annotations = {
      "eks.amazonaws.com/role-arn" = var.s3_access_iam_role_arn
    }
  }
}

# resource "kubernetes_manifest" "test_pod" {
#   manifest = yamldecode(file("manifests/test-pod.yaml"))
  
# }

resource "kubernetes_manifest" "pod_trino_test_pod" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Pod"
    "metadata" = {
      "name" = "test-pod"
      "namespace" = local.kube_namespace
    }
    "spec" = {
      "containers" = [
        {
          "args" = [
            "while true; do sleep 30; done;",
          ]
          "command" = [
            "/bin/bash",
            "-c",
            "--",
          ]
          "image" = "amazon/aws-cli:latest"
          "name" = "test"
        },
      ]
      "serviceAccountName" = "s3-access"
    }
  }
}


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
                  "value" = "jdbc:postgresql://${data.aws_db_instance.endpoint}/${data.aws_db_instance.db_name}"
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
                  "name" = "HIVE_DB_PASS"
                  "value" = data.aws_secretsmanager_secret_version.rds_password.secret_string 
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
            }
          ]
        }
      }
    }
  }
}
