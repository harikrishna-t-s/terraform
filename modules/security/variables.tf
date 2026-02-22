variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "config_bucket_name" {
  description = "Name of the S3 bucket for AWS Config"
  type        = string
}

variable "config_sns_topic_arn" {
  description = "ARN of the SNS topic for AWS Config notifications"
  type        = string
}

variable "alarm_sns_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
} 