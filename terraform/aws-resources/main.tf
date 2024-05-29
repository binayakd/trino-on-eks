
data "aws_availability_zones" "available" {}
locals {
  name   = "trino-on-eks"
  region = "ap-southeast-1"

  vpc_cidr = "10.0.0.0/24"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  kube_namespace = "trino"
  kube_sa_name = "s3-access"

  tags = {
    role = "trino-on-eks"
  }
}

provider "aws" {
  region = local.region
}


#################
# S3 Resources  #
#################

resource "aws_s3_bucket" "trino_on_eks" {
  bucket = local.name

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


#######
# VPC #
#######

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
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  eks_managed_node_groups = {
    trino = {
      min_size     = 1
      max_size     = 3
      desired_size = 1

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
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.kube_namespace}:${local.kube_sa_name}"]
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


####################
# Metastore RDS DB #
####################

resource "random_password" "rds_password"{
  length           = 16
  special          = true
  override_special = "_!%^"
}

resource "aws_secretsmanager_secret" "rds_password" {
  name = "trino-on-eks-rds-password"
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = aws_secretsmanager_secret.rds_password.id
  secret_string = random_password.rds_password.result
}


resource "aws_db_subnet_group" "trino_on_eks" {
  name       = local.name
  subnet_ids = module.vpc.public_subnets

  tags = local.tags
}

resource "aws_security_group" "trino_on_eks_rds" {
  name   = "trino-on-eks-rds"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = concat([local.vpc_cidr], var.cluster_endpoint_public_access_cidrs)
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_db_parameter_group" "trino_on_eks_rds" {
  name   = local.name
  family = "postgres16"

  parameter {
    name  = "log_connections"
    value = "0"
  }
}

resource "aws_db_instance" "trino_on_eks_rds" {
  count = var.enable_rds ? 1 : 0

  identifier             = local.name
  instance_class         = "db.t4g.micro"
  allocated_storage      = 10
  engine                 = "postgres"
  engine_version         = "16.2"
  db_name                = "trino_on_eks"
  username               = "trino_on_eks"
  password               = random_password.rds_password.result
  db_subnet_group_name   = aws_db_subnet_group.trino_on_eks.name
  vpc_security_group_ids = [aws_security_group.trino_on_eks_rds.id]
  parameter_group_name   = aws_db_parameter_group.trino_on_eks_rds.name
  publicly_accessible    = true
  skip_final_snapshot    = true
}