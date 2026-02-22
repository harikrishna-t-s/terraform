variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID for resource policies"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to restrict KMS key usage"
  type        = string
}

variable "allowed_ip_ranges" {
  description = "List of allowed IP ranges for S3 access"
  type        = list(string)
  default     = []
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for resource-based conditions"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "key_deletion_window" {
  description = "Number of days to wait before deleting KMS keys"
  type        = number
  default     = 7
}

variable "key_rotation_enabled" {
  description = "Whether to enable automatic key rotation"
  type        = bool
  default     = true
}

variable "alarm_threshold" {
  description = "Threshold for KMS key usage alarms"
  type        = number
  default     = 100
}

variable "alarm_evaluation_periods" {
  description = "Number of evaluation periods for alarms"
  type        = number
  default     = 1
}

variable "alarm_period" {
  description = "Period in seconds for alarm evaluation"
  type        = number
  default     = 300
} 