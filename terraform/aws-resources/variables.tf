variable "name" {
  type        = string
  description = "Common name of the S3 bucket, EKS cluster, RDS instance and other resources"
}

variable "region" {
  type        = string
  description = "AWS region to use"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block to use"

}

variable "kube_namespace_name" {
  type        = string
  description = "Kubernetes Namespace name where the Trino and Metastore deployments will be done to"

}

variable "kube_sa_name" {
  type        = string
  description = "Kubernetes Service account name, which will be used to access S3 using IAM/IRSA"
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
}

variable "kubeconfig_location" {
  type        = string
  description = "Location to save the Kubeconfig file to"
}

variable "enable_eks" {
  type        = bool
  default     = true
  description = "Turn on or off the EKS resources"
}

variable "enable_rds" {
  type        = bool
  default     = true
  description = "Turn on or off the RDS resources"
}

