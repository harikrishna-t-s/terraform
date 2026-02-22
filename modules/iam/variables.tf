# Environment and Tagging
variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID for resource policies"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to restrict access"
  type        = string
}

variable "allowed_ip_ranges" {
  description = "List of allowed IP ranges for access"
  type        = list(string)
  default     = []
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for resource-based conditions"
  type        = string
}

variable "s3_kms_key_arn" {
  description = "ARN of the KMS key used for S3 encryption"
  type        = string
}

variable "secrets_kms_key_arn" {
  description = "ARN of the KMS key used for Secrets Manager"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# KMS Configuration
variable "kms_key_id" {
  description = "ID of the KMS key to attach policies to"
  type        = string
}

# EC2 Configuration
variable "enable_ec2_ssm" {
  description = "Whether to enable Systems Manager access for EC2 instances"
  type        = bool
  default     = true
}

variable "enable_ec2_cloudwatch" {
  description = "Whether to enable CloudWatch access for EC2 instances"
  type        = bool
  default     = true
}

# Lambda Configuration
variable "enable_lambda_basic" {
  description = "Whether to enable basic Lambda execution policy"
  type        = bool
  default     = true
}

# ECS Configuration
variable "enable_ecs_task_execution" {
  description = "Whether to enable ECS task execution policy"
  type        = bool
  default     = true
}

# RDS Configuration
variable "enable_rds_monitoring" {
  description = "Whether to enable RDS monitoring role"
  type        = bool
  default     = true
}

# Policy Configuration
variable "additional_ec2_policies" {
  description = "Additional IAM policy ARNs to attach to EC2 role"
  type        = list(string)
  default     = []
}

variable "additional_lambda_policies" {
  description = "Additional IAM policy ARNs to attach to Lambda role"
  type        = list(string)
  default     = []
}

variable "additional_ecs_policies" {
  description = "Additional IAM policy ARNs to attach to ECS roles"
  type        = list(string)
  default     = []
}

# Path Configuration
variable "iam_path" {
  description = "Path to create IAM resources under"
  type        = string
  default     = "/"
}

# Name Prefix Configuration
variable "name_prefix" {
  description = "Prefix to use for resource names"
  type        = string
  default     = ""
}

variable "external_id" {
  description = "External ID for cross-account access"
  type        = string
  default     = ""
} 