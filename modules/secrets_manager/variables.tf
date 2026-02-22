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

variable "secret_name" {
  description = "Name of the secret (will be prefixed with project-environment)"
  type        = string
}

variable "secret_description" {
  description = "Description of the secret"
  type        = string
  default     = "Managed by Terraform"
}

variable "initial_secret_value" {
  description = "Initial value for the secret"
  type        = string
  sensitive   = true
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

variable "rotation_strategy" {
  description = "Strategy for secret rotation (single_user, alternating_users, custom)"
  type        = string
  default     = "single_user"

  validation {
    condition     = contains(["single_user", "alternating_users", "custom"], var.rotation_strategy)
    error_message = "Rotation strategy must be one of: single_user, alternating_users, custom"
  }
}

variable "rotation_days" {
  description = "Number of days between automatic rotations"
  type        = number
  default     = 30
}

variable "rotation_schedule" {
  description = "Custom rotation schedule expression (required for custom rotation strategy)"
  type        = string
  default     = "rate(30 days)"
}

variable "rotation_lambda_zip" {
  description = "Path to the ZIP file containing the custom rotation Lambda function code (required for custom rotation strategy)"
  type        = string
  default     = null
}

variable "custom_rotation_lambda_name" {
  description = "Name of the custom rotation Lambda function (required for custom rotation strategy)"
  type        = string
  default     = null
}

variable "lambda_runtime" {
  description = "Runtime for the rotation Lambda function"
  type        = string
  default     = "python3.9"

  validation {
    condition     = contains(["python3.7", "python3.8", "python3.9", "nodejs14.x", "nodejs16.x", "java11"], var.lambda_runtime)
    error_message = "Lambda runtime must be one of: python3.7, python3.8, python3.9, nodejs14.x, nodejs16.x, java11"
  }
}

variable "lambda_timeout" {
  description = "Timeout in seconds for the rotation Lambda function"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Memory size in MB for the rotation Lambda function"
  type        = number
  default     = 128
}

variable "custom_rotation_permissions" {
  description = "Additional IAM permissions required for custom rotation"
  type        = list(string)
  default     = []
}

variable "custom_rotation_resources" {
  description = "Additional resources required for custom rotation"
  type        = list(string)
  default     = []
}

variable "use_parameter_store" {
  description = "Whether to use Parameter Store instead of Secrets Manager for non-sensitive configuration"
  type        = bool
  default     = false
}

variable "parameter_tier" {
  description = "Parameter Store tier (Standard or Advanced)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Advanced"], var.parameter_tier)
    error_message = "Parameter tier must be either Standard or Advanced"
  }
}

variable "parameter_type" {
  description = "Parameter Store type (String, StringList, or SecureString)"
  type        = string
  default     = "SecureString"

  validation {
    condition     = contains(["String", "StringList", "SecureString"], var.parameter_type)
    error_message = "Parameter type must be one of: String, StringList, SecureString"
  }
}

variable "vault_integration" {
  description = "Whether to integrate with HashiCorp Vault"
  type        = bool
  default     = false
}

variable "vault_address" {
  description = "Address of the HashiCorp Vault server"
  type        = string
  default     = null
}

variable "vault_path" {
  description = "Path in Vault where the secret should be stored"
  type        = string
  default     = null
}

variable "alarm_sns_topic_arn" {
  description = "ARN of the SNS topic for rotation alarms"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
} 