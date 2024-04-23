output "kubeconfig" {
  value = var.enable_eks ? abspath("${var.kubeconfig_location}") : null
}

output "s3_access_iam_role_arn" {
  value = var.enable_eks ? module.trino_s3_access_irsa[0].iam_role_arn : null
}

output "trino_on_eks_rds_hostname" {
  description = "RDS instance hostname"
  value       = var.enable_rds ? aws_db_instance.trino_on_eks_rds[0].address : null
  # sensitive   = true
}

output "trino_on_eks_rds_port" {
  description = "RDS instance port"
  value       = var.enable_rds ? aws_db_instance.trino_on_eks_rds[0].port : null
  # sensitive   = true
}

output "trino_on_eks_rds_username" {
  description = "RDS instance root username"
  value       = var.enable_rds ? aws_db_instance.trino_on_eks_rds[0].username: null
  # sensitive   = true
}

output "trino_on_eks_rds_password" {
  description = "RDS instance root password"
  value       = random_password.rds_password.result
  sensitive   = true
}