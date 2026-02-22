# Infrastructure Configuration
variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "launch_template_id" {
  description = "ID of the launch template to use"
  type        = string

  validation {
    condition     = can(regex("^lt-[a-z0-9]+$", var.launch_template_id))
    error_message = "The launch template ID must be valid and start with 'lt-'"
  }
}

variable "launch_template_version" {
  description = "Version of the launch template to use"
  type        = string
  default     = "$Latest"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Auto Scaling Group"
  type        = list(string)

  validation {
    condition     = alltrue([for subnet in var.subnet_ids : can(regex("^subnet-[a-z0-9]+$", subnet))])
    error_message = "Subnet IDs must be valid and start with 'subnet-'"
  }
}

variable "target_group_arns" {
  description = "List of target group ARNs to associate with the Auto Scaling Group"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for tg in var.target_group_arns : can(regex("^arn:aws:elasticloadbalancing:", tg))])
    error_message = "Target group ARNs must be valid ELB ARNs"
  }
}

variable "scaling_config" {
  description = "Configuration for the Auto Scaling Group"
  type = object({
    desired_capacity = number
    max_size        = number
    min_size        = number
    health_check_type = string
    health_check_grace_period = number
    mixed_instances_policy = optional(object({
      on_demand_percentage_above_base_capacity = number
      spot_allocation_strategy                 = string
      spot_instance_pools                      = number
      instance_types                           = list(object({
        instance_type     = string
        weighted_capacity = optional(number)
      }))
    }))
    lifecycle_hooks = optional(list(object({
      name                    = string
      lifecycle_transition    = string
      default_result         = string
      heartbeat_timeout      = number
      notification_metadata  = optional(string)
      notification_target_arn = optional(string)
      role_arn               = optional(string)
    })))
    scheduled_actions = optional(list(object({
      name             = string
      min_size         = optional(number)
      max_size         = optional(number)
      desired_capacity = optional(number)
      start_time       = optional(string)
      end_time         = optional(string)
      recurrence       = optional(string)
      time_zone        = optional(string)
    })))
  })

  validation {
    condition     = var.scaling_config.max_size >= var.scaling_config.min_size
    error_message = "max_size must be greater than or equal to min_size"
  }

  validation {
    condition     = var.scaling_config.desired_capacity >= var.scaling_config.min_size && var.scaling_config.desired_capacity <= var.scaling_config.max_size
    error_message = "desired_capacity must be between min_size and max_size"
  }

  validation {
    condition     = contains(["EC2", "ELB"], var.scaling_config.health_check_type)
    error_message = "health_check_type must be either 'EC2' or 'ELB'"
  }
}

variable "scaling_policies" {
  description = "Configuration for scaling policies"
  type = object({
    target_tracking = optional(map(object({
      predefined_metric_type = string
      resource_label        = optional(string)
      target_value         = number
      disable_scale_in     = optional(bool)
      estimated_instance_warmup = optional(number)
    })))
    step_scaling = optional(map(object({
      adjustment_type       = string
      cooldown             = number
      metric_aggregation_type = string
      step_adjustments     = list(object({
        scaling_adjustment          = number
        metric_interval_lower_bound = optional(number)
        metric_interval_upper_bound = optional(number)
      }))
    })))
  })
  default = {}
}

variable "app_security_group_id" {
  description = "ID of the application security group"
  type        = string
}

variable "instance_profile_name" {
  description = "Name of the IAM instance profile"
  type        = string
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB target group to register instances with"
  type        = string
}

# Instance Configuration
variable "ami_id" {
  description = "ID of the AMI to use for instances"
  type        = string
  default     = null # Will use latest Amazon Linux 2 AMI if not specified
}

variable "instance_type" {
  description = "Type of instance to launch"
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Port on which the application listens"
  type        = number
  default     = 8080
  validation {
    condition     = var.app_port >= 1 && var.app_port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}

# Auto Scaling Configuration
variable "desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 2
  validation {
    condition     = var.desired_capacity >= var.min_size && var.desired_capacity <= var.max_size
    error_message = "Desired capacity must be between min_size and max_size."
  }
}

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 2
  validation {
    condition     = var.min_size >= 1
    error_message = "Minimum size must be at least 1."
  }
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 4
  validation {
    condition     = var.max_size >= var.min_size
    error_message = "Maximum size must be greater than or equal to minimum size."
  }
}

variable "health_check_type" {
  description = "Type of health check to use (EC2 or ELB)"
  type        = string
  default     = "ELB"
  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "Health check type must be either EC2 or ELB."
  }
}

variable "health_check_grace_period" {
  description = "Time after instance comes into service before checking health"
  type        = number
  default     = 300
  validation {
    condition     = var.health_check_grace_period >= 0
    error_message = "Health check grace period must be non-negative."
  }
}

variable "artifact_bucket" {
  description = "Name of the S3 bucket containing the application artifact"
  type        = string
}

variable "artifact_key" {
  description = "Key of the application artifact in the S3 bucket"
  type        = string
}

# Monitoring Configuration
variable "sns_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms"
  type        = string
}

# Resource Tagging
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
} 