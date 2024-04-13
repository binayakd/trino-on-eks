output "kubeconfig" {
  value = var.enable_eks ? abspath("${var.kubeconfig_location}") : null
}