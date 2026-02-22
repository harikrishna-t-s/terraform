# Terraform State Bucket
output "terraform_state_bucket_id" {
  description = "ID of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

# ALB Logs Bucket
output "alb_logs_bucket_id" {
  description = "ID of the S3 bucket for ALB logs"
  value       = aws_s3_bucket.alb_logs.id
}

output "alb_logs_bucket_arn" {
  description = "ARN of the S3 bucket for ALB logs"
  value       = aws_s3_bucket.alb_logs.arn
}

# CloudTrail Logs Bucket
output "cloudtrail_logs_bucket_id" {
  description = "ID of the S3 bucket for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail_logs.id
}

output "cloudtrail_logs_bucket_arn" {
  description = "ARN of the S3 bucket for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail_logs.arn
}

# AWS Config Logs Bucket
output "config_logs_bucket_id" {
  description = "ID of the S3 bucket for AWS Config logs"
  value       = aws_s3_bucket.config_logs.id
}

output "config_logs_bucket_arn" {
  description = "ARN of the S3 bucket for AWS Config logs"
  value       = aws_s3_bucket.config_logs.arn
}

# Application Logs Bucket
output "app_logs_bucket_id" {
  description = "ID of the S3 bucket for application logs"
  value       = aws_s3_bucket.app_logs.id
}

output "app_logs_bucket_arn" {
  description = "ARN of the S3 bucket for application logs"
  value       = aws_s3_bucket.app_logs.arn
}

# Database Backups Bucket
output "db_backups_bucket_id" {
  description = "ID of the S3 bucket for database backups"
  value       = aws_s3_bucket.db_backups.id
}

output "db_backups_bucket_arn" {
  description = "ARN of the S3 bucket for database backups"
  value       = aws_s3_bucket.db_backups.arn
}

# All Bucket ARNs
output "all_bucket_arns" {
  description = "Map of all bucket ARNs"
  value = {
    terraform_state = aws_s3_bucket.terraform_state.arn
    alb_logs       = aws_s3_bucket.alb_logs.arn
    cloudtrail_logs = aws_s3_bucket.cloudtrail_logs.arn
    config_logs    = aws_s3_bucket.config_logs.arn
    app_logs       = aws_s3_bucket.app_logs.arn
    db_backups     = aws_s3_bucket.db_backups.arn
  }
} 