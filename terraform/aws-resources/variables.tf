variable "enable_eks" {
  type    = bool
  default = true
  description = "Turn on or off the EKS resources"
}

variable "enable_rds" {
  type    = bool
  default = true
  description = "Turn on or off the RDS resources"
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
}

variable "kubeconfig_location" {
  type = string
  description = "Location to save the Kubeconfig file to"
}