locals {
  tags = {
    role = var.name
  }
}

data "aws_eks_cluster" "trino_on_eks" {
  name = var.name
}

data "aws_eks_cluster_auth" "trino_on_eks" {
  name = var.name
}

data "aws_iam_role" "trino_s3_access_role" {
  name = "trino_s3_access_role"
}

data "aws_db_instance" "trino_on_eks_rds" {
  db_instance_identifier = var.name
}

data "aws_secretsmanager_secret" "rds_password" {
  name = "trino-on-eks-rds-password"

}

data "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = data.aws_secretsmanager_secret.rds_password.id
}


provider "kubernetes" {
  host                   = data.aws_eks_cluster.trino_on_eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.trino_on_eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.trino_on_eks.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.trino_on_eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.trino_on_eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.trino_on_eks.token
  }
}

resource "kubernetes_namespace" "trino" {
  metadata {
    name = var.kube_namespace_name
  }
}

resource "kubernetes_service_account" "trino_s3_access_sa" {
  depends_on = [kubernetes_namespace.trino]
  metadata {
    name      = var.kube_sa_name
    namespace = var.kube_namespace_name

    annotations = {
      "eks.amazonaws.com/role-arn" = data.aws_iam_role.trino_s3_access_role.arn
    }
  }
}


resource "helm_release" "metastore" {
  depends_on = [kubernetes_service_account.trino_s3_access_sa]

  name      = "metastore"
  namespace = var.kube_namespace_name
  chart     = "../../metastore/helm-chart"

  set {
    name  = "image"
    value = "ghcr.io/binayakd/metastore:4.0.0-hadoop-3.4.0"
  }

  set {
    name  = "dbUrl"
    value = "jdbc:postgresql://${data.aws_db_instance.trino_on_eks_rds.endpoint}/${data.aws_db_instance.trino_on_eks_rds.db_name}"
  }
  set {
    name  = "dbUser"
    value = data.aws_db_instance.trino_on_eks_rds.master_username
  }

  set {
    name  = "dbPassword"
    value = data.aws_secretsmanager_secret_version.rds_password.secret_string
  }
  set {
    name  = "dbDriver"
    value = "org.postgresql.Driver"
  }

  set {
    name  = "s3Bucket"
    value = "s3://trino-on-eks"
  }

  set {
    name  = "serviceAccountName"
    value = var.kube_sa_name
  }
}


resource "helm_release" "trino" {
  name      = "trino"
  namespace = var.kube_namespace_name

  repository = "https://trinodb.github.io/charts"
  chart      = "trino"

  values = [
    "${file("trino-helm-values.yaml")}"
  ]

  set {
    name  = "serviceAccount.name"
    value = var.kube_sa_name
  }
}