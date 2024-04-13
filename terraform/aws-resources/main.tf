provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

locals {
  name   = "trino-on-eks"
  region = "ap-southeast-1"

  vpc_cidr = "10.0.0.0/24"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  kube_sa_name = "s3-access"

  tags = {
    role = "trino-on-eks"
  }
}

resource "aws_s3_bucket" "trino_on_eks" {
  bucket = local.name

  tags = local.tags
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = local.vpc_cidr

  azs                     = local.azs
  public_subnets          = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  enable_dns_support      = true
  enable_dns_hostnames    = true
  map_public_ip_on_launch = true

  tags = local.tags
}


data "aws_iam_policy_document" "trino_s3_access" {
  statement {
    actions = [
      "s3:ListBucket"
    ]

    resources = [aws_s3_bucket.trino_on_eks.arn]

  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = ["${aws_s3_bucket.trino_on_eks.arn}/*"]

  }
}

resource "aws_iam_policy" "trino_s3_access_policy" {
  name   = "trino_s3_access_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.trino_s3_access.json
}


#################
# EKS Resources #
#################

module "eks" {
  count = var.enable_eks ? 1 : 0

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = "1.29"

  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  eks_managed_node_groups = {
    trino = {
      min_size     = 1
      max_size     = 3
      desired_size = 3

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
    }
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  tags = local.tags
}


module "trino_s3_access_irsa" {
  count = var.enable_eks ? 1 : 0

  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"

  create_role                   = true
  role_name                     = "trino_s3_access_role"
  provider_url                  = module.eks[0].oidc_provider
  role_policy_arns              = [aws_iam_policy.trino_s3_access_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:default:${local.kube_sa_name}"]
}

resource "local_sensitive_file" "kubeconfig" {
  count = var.enable_eks ? 1 : 0

  content = templatefile("${path.module}/templates/kubeconfig.tpl", {
    cluster_name = module.eks[0].cluster_name,
    clusterca    = module.eks[0].cluster_certificate_authority_data,
    endpoint     = module.eks[0].cluster_endpoint,
    region       = local.region
  })
  filename = var.kubeconfig_location
}

#################


##################
# Kube Resources #
##################

# data "aws_eks_cluster_auth" "trino_eks" {
#   name = local.name
# }

# provider "kubernetes" {
#   host                   = module.eks[0].cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks[0].cluster_certificate_authority_data)
#   token                  = data.aws_eks_cluster_auth.trino_eks.token
# }

# resource "kubernetes_service_account" "trino_s3_access_sa" {
#   metadata {
#     namespace = "default"
#     name      = local.kube_sa_name

#     annotations = {
#       "eks.amazonaws.com/role-arn" = module.n [0].iam_role_arn
#     }
#   }
#   automount_service_account_token = true
# }

# resource "kubernetes_secret" "trino_s3_access_sa_secret" {
#   metadata {
#     annotations = {
#       "kubernetes.io/service-account.name" = kubernetes_service_account.trino_s3_access_sa.metadata.0.name
#     }
#     namespace     = "default"
#     generate_name = "${kubernetes_service_account.trino_s3_access_sa.metadata.0.name}-token-"
#   }

#   type = "kubernetes.io/service-account-token"
#   wait_for_service_account_token = true
# }

##################