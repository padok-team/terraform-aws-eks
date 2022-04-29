output "this" {
  description = "All ouputs from the module"
  value       = module.this
}

output "external_secret_role_arn" {
  description = "The ARN of the external secret role"
  value       = aws_iam_role.external_secret.arn
}

output "external_dns_role_arn" {
  description = "The ARN of the external dns role"
  value       = aws_iam_role.external_dns.arn
}

output "cluster_autoscaler_role_arn" {
  description = "The ARN of the cluster autoscaler role"
  value       = aws_iam_role.cluster_autoscaler.arn
}