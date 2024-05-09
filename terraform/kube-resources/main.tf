locals {
  name   = "trino-on-eks"
  region = "ap-southeast-1"

  kube_namespace = "trino"
  kube_sa_name = "s3-access"

  tags = {
    role = "trino-on-eks"
  }
}

data "aws_eks_cluster" "trino_on_eks" {
  name = local.name
}

data "aws_eks_cluster_auth" "trino_on_eks" {
  name = local.name
}

data "aws_iam_role" "example" {
  name = "an_example_role_name"
}

data "aws_db_instance" "trino_on_eks_rds" {
  db_instance_identifier = local.name
}

data "aws_secretsmanager_secret" "rds_password" {
  name = "trino-on-eks-rds-password"

}

data "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = data.aws_secretsmanager_secret.rds_password.id
}


provider "kubernetes" {
  host                   = data.aws_eks_cluster.trino_on_eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.default.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.trino_on_eks.endpoint
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


resource "helm_release" "metastore" {
  name = "metastore"
  namespace = local.kube_namespace
  chart = "../../metastore/helm-chart"

  set {
    name = image
    value = "ghcr.io/binayakd/hive-standalone-metastore:4.0.0-hadoop-3.4.0"
  }

  set {
    name = dbUrl
    value = "jdbc:postgresql://${data.aws_db_instance.endpoint}/${data.aws_db_instance.db_name}"
  }
  set {
    name = dbUser
    value = data.aws_db_instance.master_username
  }

  set{
    name = dbPassword
    value = data.aws_secretsmanager_secret_version.rds_password.secret_string 
  }
  set {
    name = dbDriver
    value = "org.postgresql.Driver"
  }

  set {
    name = s3Bucket
    value = "s3://trino-on-eks"
  }

  set {
    name = serviceAccountName
    value = local.kube_sa_name
  }
  
}


resource "helm_release" "trino" {
  name = "trino"
  namespace = local.kube_namespace

  repository = "https://trinodb.github.io/charts/"
  chart      = "trino/trino"

}