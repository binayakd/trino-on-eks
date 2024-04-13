locals {
  name   = "trino-on-eks"
  region = "ap-southeast-1"

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

resource "kubernetes_service_account" "trino_s3_access_sa" {
  metadata {
    name = local.kube_sa_name

    annotations = {
      "eks.amazonaws.com/role-arn" = module.trino_s3_access_irsa.iam_role_arn
    }
  }
}