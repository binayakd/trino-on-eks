variable "enable_eks" {
  type    = bool
  default = true
}

variable "enable_rds" {
  type    = bool
  default = true
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
}

variable "kubeconfig_location" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type = string
}
