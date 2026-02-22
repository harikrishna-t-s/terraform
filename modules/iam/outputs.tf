output "app_role_arn" {
  description = "ARN of the application server IAM role"
  value       = aws_iam_role.app.arn
}

output "app_instance_profile_name" {
  description = "Name of the application server instance profile"
  value       = aws_iam_instance_profile.app.name
}

output "db_role_arn" {
  description = "ARN of the database IAM role"
  value       = aws_iam_role.db.arn
}

output "terraform_role_arn" {
  description = "ARN of the Terraform service account IAM role"
  value       = aws_iam_role.terraform.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.main.arn
}

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.main.key_id
}

output "kms_alias_arn" {
  description = "ARN of the KMS alias"
  value       = aws_kms_alias.main.arn
}

# EC2 Role Information
output "ec2_role_arn" {
  description = "ARN of the IAM role for EC2 instances"
  value       = aws_iam_role.ec2.arn
}

output "ec2_role_name" {
  description = "Name of the IAM role for EC2 instances"
  value       = aws_iam_role.ec2.name
}

output "ec2_instance_profile_arn" {
  description = "ARN of the IAM instance profile for EC2 instances"
  value       = aws_iam_instance_profile.ec2.arn
}

output "ec2_instance_profile_name" {
  description = "Name of the IAM instance profile for EC2 instances"
  value       = aws_iam_instance_profile.ec2.name
}

# Lambda Role Information
output "lambda_role_arn" {
  description = "ARN of the IAM role for Lambda functions"
  value       = aws_iam_role.lambda.arn
}

output "lambda_role_name" {
  description = "Name of the IAM role for Lambda functions"
  value       = aws_iam_role.lambda.name
}

# ECS Role Information
output "ecs_task_role_arn" {
  description = "ARN of the IAM role for ECS tasks"
  value       = aws_iam_role.ecs_task.arn
}

output "ecs_task_role_name" {
  description = "Name of the IAM role for ECS tasks"
  value       = aws_iam_role.ecs_task.name
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the IAM role for ECS task execution"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_execution_role_name" {
  description = "Name of the IAM role for ECS task execution"
  value       = aws_iam_role.ecs_task_execution.name
}

# RDS Monitoring Role Information
output "rds_monitoring_role_arn" {
  description = "ARN of the IAM role for RDS monitoring"
  value       = aws_iam_role.rds_monitoring.arn
}

output "rds_monitoring_role_name" {
  description = "Name of the IAM role for RDS monitoring"
  value       = aws_iam_role.rds_monitoring.name
}

# Policy Information
output "ec2_ssm_policy_arn" {
  description = "ARN of the IAM policy for EC2 SSM access"
  value       = aws_iam_policy.ec2_ssm.arn
}

output "ec2_cloudwatch_policy_arn" {
  description = "ARN of the IAM policy for EC2 CloudWatch access"
  value       = aws_iam_policy.ec2_cloudwatch.arn
}

output "lambda_basic_policy_arn" {
  description = "ARN of the IAM policy for basic Lambda execution"
  value       = aws_iam_policy.lambda_basic.arn
}

output "ecs_task_execution_policy_arn" {
  description = "ARN of the IAM policy for ECS task execution"
  value       = aws_iam_policy.ecs_task_execution.arn
} 