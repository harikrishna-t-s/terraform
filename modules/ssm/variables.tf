variable "environment" {
  description = "Environment name"
  type        = string
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group to target"
  type        = string
  default     = null
}

variable "create_activation" {
  description = "Whether to create SSM activation"
  type        = bool
  default     = false
}

variable "registration_limit" {
  description = "Maximum number of managed instances that can be registered using this activation"
  type        = number
  default     = 1000
}

variable "create_maintenance_window" {
  description = "Whether to create a maintenance window"
  type        = bool
  default     = true
}

variable "maintenance_window_schedule" {
  description = "Schedule of the maintenance window (cron/rate expression)"
  type        = string
  default     = "cron(0 0 ? * SUN *)"  # Every Sunday at midnight
}

variable "maintenance_window_duration" {
  description = "Duration of the maintenance window in hours"
  type        = number
  default     = 3
}

variable "maintenance_window_cutoff" {
  description = "Number of hours before the end of the maintenance window that systems stop scheduling new tasks for execution"
  type        = number
  default     = 1
}

variable "create_patch_group" {
  description = "Whether to create a patch group"
  type        = bool
  default     = true
}

variable "create_patch_baseline" {
  description = "Whether to create a patch baseline"
  type        = bool
  default     = true
}

variable "patch_approval_days" {
  description = "Number of days to wait after a patch is released before it is approved"
  type        = number
  default     = 7
}

variable "create_patch_association" {
  description = "Whether to create a patch association"
  type        = bool
  default     = true
}

variable "target_instance_ids" {
  description = "List of instance IDs to target for patching"
  type        = list(string)
  default     = []
}

variable "patch_schedule" {
  description = "Schedule for patch installation (cron/rate expression)"
  type        = string
  default     = "cron(0 0 ? * SUN *)"  # Every Sunday at midnight
}

variable "create_custom_document" {
  description = "Whether to create a custom SSM document"
  type        = bool
  default     = false
}

variable "custom_document_content" {
  description = "Content of the custom SSM document"
  type        = string
  default     = ""
}

variable "custom_document_parameters" {
  description = "Parameters for the custom SSM document"
  type        = map(list(string))
  default     = {}
}

variable "custom_document_schedule" {
  description = "Schedule for custom document execution (cron/rate expression)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
} 