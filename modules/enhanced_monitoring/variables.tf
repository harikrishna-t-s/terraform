variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "alarm_sns_topic_arn" {
  description = "ARN of the SNS topic for alarms"
  type        = string
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
}

variable "budget_notification_email" {
  description = "Email address for budget notifications"
  type        = string
}

variable "log_destination_arn" {
  description = "ARN of the destination for log forwarding (e.g., Kinesis, Lambda, or another CloudWatch Logs group)"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
} 