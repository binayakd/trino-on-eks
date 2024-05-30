variable "name" {
  type        = string
  description = "Common name of the S3 bucket, EKS cluster, RDS instance and other resources"
}

variable "region" {
  type        = string
  description = "AWS region to use"
}

variable "kube_namespace_name" {
  type        = string
  description = "Kubernetes Namespace name where the Trino and Metastore deployments will be done to"

}

variable "kube_sa_name" {
  type        = string
  description = "Kubernetes Service account name, which will be used to access S3 using IAM/IRSA"
}

