variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# Retention Periods
variable "alb_log_retention_days" {
  description = "Number of days to retain ALB logs"
  type        = number
  default     = 90
  validation {
    condition     = var.alb_log_retention_days >= 1
    error_message = "Log retention days must be at least 1."
  }
}

variable "app_log_retention_days" {
  description = "Number of days to retain application logs"
  type        = number
  default     = 90
  validation {
    condition     = var.app_log_retention_days >= 1
    error_message = "Log retention days must be at least 1."
  }
}

variable "db_backup_retention_days" {
  description = "Number of days to retain database backups"
  type        = number
  default     = 365
  validation {
    condition     = var.db_backup_retention_days >= 1
    error_message = "Backup retention days must be at least 1."
  }
}

# Bucket Names (Optional - will use default naming if not specified)
variable "terraform_state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = ""
}

variable "alb_logs_bucket_name" {
  description = "Name of the S3 bucket for ALB logs"
  type        = string
  default     = ""
}

variable "cloudtrail_logs_bucket_name" {
  description = "Name of the S3 bucket for CloudTrail logs"
  type        = string
  default     = ""
}

variable "config_logs_bucket_name" {
  description = "Name of the S3 bucket for AWS Config logs"
  type        = string
  default     = ""
}

variable "app_logs_bucket_name" {
  description = "Name of the S3 bucket for application logs"
  type        = string
  default     = ""
}

variable "db_backups_bucket_name" {
  description = "Name of the S3 bucket for database backups"
  type        = string
  default     = ""
}

# KMS Configuration
variable "kms_key_arn" {
  description = "ARN of the KMS key to use for bucket encryption. If not provided, a new key will be created."
  type        = string
  default     = ""
}

# Versioning Configuration
variable "enable_versioning" {
  description = "Enable versioning for all buckets"
  type        = bool
  default     = true
}

# Lifecycle Rules
variable "enable_lifecycle_rules" {
  description = "Enable lifecycle rules for all buckets"
  type        = bool
  default     = true
}

# Public Access Block
variable "block_public_access" {
  description = "Block public access to all buckets"
  type        = bool
  default     = true
} 