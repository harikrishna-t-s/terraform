output "maintenance_window_id" {
  description = "ID of the maintenance window"
  value       = var.create_maintenance_window ? aws_ssm_maintenance_window.example[0].id : null
}

output "maintenance_window_arn" {
  description = "ARN of the maintenance window"
  value       = var.create_maintenance_window ? aws_ssm_maintenance_window.example[0].arn : null
}

output "patch_baseline_id" {
  description = "ID of the patch baseline"
  value       = var.create_patch_baseline ? aws_ssm_patch_baseline.example[0].id : null
}

output "patch_baseline_arn" {
  description = "ARN of the patch baseline"
  value       = var.create_patch_baseline ? aws_ssm_patch_baseline.example[0].arn : null
}

output "custom_document_name" {
  description = "Name of the custom SSM document"
  value       = var.create_custom_document ? aws_ssm_document.example[0].name : null
}

output "custom_document_arn" {
  description = "ARN of the custom SSM document"
  value       = var.create_custom_document ? aws_ssm_document.example[0].arn : null
}

output "maintenance_role_arn" {
  description = "ARN of the IAM role for maintenance window tasks"
  value       = aws_iam_role.ssm_maintenance.arn
}

output "maintenance_role_name" {
  description = "Name of the IAM role for maintenance window tasks"
  value       = aws_iam_role.ssm_maintenance.name
} 