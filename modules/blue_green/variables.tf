variable "name_prefix" {
  description = "Prefix for naming all resources in this environment (e.g., 'prod-blue', 'prod-green')"
  type        = string
}

variable "ami_id" {
  description = "Optional custom AMI ID. If not provided, latest Amazon Linux 2 AMI will be used."
  type        = string
  default     = null
}

variable "instance_config" {
  description = "Configuration for the EC2 instance (type, block devices, metadata options)"
  type        = any
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the instance."
  type        = list(string)
}

variable "associate_public_ip" {
  description = "Whether to associate a public IP address with the instance."
  type        = bool
  default     = false
}

variable "user_data_template_path" {
  description = "Path to the user data template file."
  type        = string
}

variable "user_data_vars" {
  description = "Variables to pass to the user data template."
  type        = map(any)
  default     = {}
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Auto Scaling Group."
  type        = list(string)
}

variable "target_group_arns" {
  description = "List of target group ARNs to associate with the Auto Scaling Group."
  type        = list(string)
  default     = []
}

variable "scaling_config" {
  description = "Configuration for the Auto Scaling Group (min/max/desired, health checks, mixed instances, etc.)"
  type        = any
}

variable "scaling_policies" {
  description = "Configuration for scaling policies (target tracking, step scaling, etc.)"
  type        = any
  default     = {}
}

variable "alarm_config" {
  description = "Configuration for CloudWatch alarms."
  type        = any
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener"
  type        = string
}

variable "target_port" {
  description = "Port on which targets receive traffic"
  type        = number
  default     = 80
}

variable "target_protocol" {
  description = "Protocol to use for routing traffic to the targets"
  type        = string
  default     = "HTTP"
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive health checks successes required before considering an unhealthy target healthy"
  type        = number
  default     = 2
}

variable "health_check_interval" {
  description = "Approximate amount of time, in seconds, between health checks of an individual target"
  type        = number
  default     = 30
}

variable "health_check_matcher" {
  description = "HTTP codes to use when checking for a successful response from a target"
  type        = string
  default     = "200"
}

variable "health_check_path" {
  description = "Destination for the health check request"
  type        = string
  default     = "/"
}

variable "health_check_port" {
  description = "Port to use to connect with the target"
  type        = string
  default     = "traffic-port"
}

variable "health_check_protocol" {
  description = "Protocol to use to connect with the target"
  type        = string
  default     = "HTTP"
}

variable "health_check_timeout" {
  description = "Amount of time, in seconds, during which no response means a failed health check"
  type        = number
  default     = 5
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive health check failures required before considering the target unhealthy"
  type        = number
  default     = 2
}

variable "blue_path_patterns" {
  description = "List of path patterns for blue environment"
  type        = list(string)
  default     = ["/blue/*"]
}

variable "green_path_patterns" {
  description = "List of path patterns for green environment"
  type        = list(string)
  default     = ["/green/*"]
}

variable "blue_launch_template_id" {
  description = "ID of the launch template for blue environment"
  type        = string
}

variable "green_launch_template_id" {
  description = "ID of the launch template for green environment"
  type        = string
}

variable "desired_capacity" {
  description = "Desired number of instances in each ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in each ASG"
  type        = number
  default     = 4
}

variable "min_size" {
  description = "Minimum number of instances in each ASG"
  type        = number
  default     = 1
}

variable "cpu_utilization_high_threshold" {
  description = "CPU utilization threshold for scaling up"
  type        = number
  default     = 80
}

variable "cpu_utilization_low_threshold" {
  description = "CPU utilization threshold for scaling down"
  type        = number
  default     = 20
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarms are triggered"
  type = object({
    ok_actions    = list(string)
    alarm_actions = list(string)
    insufficient_data_actions = list(string)
  })
  default = {
    ok_actions    = []
    alarm_actions = []
    insufficient_data_actions = []
  }
}

variable "enable_alarms" {
  description = "Enable or disable CloudWatch alarms"
  type = object({
    cpu_utilization = bool
    memory_utilization = bool
    disk_utilization = bool
    request_count = bool
    error_rate = bool
    latency = bool
  })
  default = {
    cpu_utilization = true
    memory_utilization = true
    disk_utilization = true
    request_count = true
    error_rate = true
    latency = true
  }
}

variable "alarm_description_prefix" {
  description = "Prefix to add to all alarm descriptions"
  type        = string
  default     = "This metric monitors"
}

variable "alarm_name_prefix" {
  description = "Prefix to add to all alarm names"
  type        = string
  default     = ""
}

variable "alarm_tags" {
  description = "Additional tags to add to CloudWatch alarms. These tags will be merged with common tags and environment-specific tags."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for k, v in var.alarm_tags : can(regex("^[\\w\\s\\+\\-\\=\\.\\:\\/@]+$", v))])
    error_message = "Tag values must contain only alphanumeric characters, spaces, and the following special characters: + - = . : / @"
  }

  validation {
    condition     = alltrue([for k, v in var.alarm_tags : length(k) <= 128])
    error_message = "Tag keys must be 128 characters or less"
  }

  validation {
    condition     = alltrue([for k, v in var.alarm_tags : length(v) <= 256])
    error_message = "Tag values must be 256 characters or less"
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "metadata_options" {
  description = "Customize the metadata options for the instance"
  type = object({
    http_endpoint               = optional(string, "enabled")
    http_tokens                 = optional(string, "required")
    http_put_response_hop_limit = optional(number, 1)
    instance_metadata_tags      = optional(string, "enabled")
  })
  default = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  validation {
    condition     = contains(["enabled", "disabled"], var.metadata_options.http_endpoint)
    error_message = "http_endpoint must be either 'enabled' or 'disabled'"
  }

  validation {
    condition     = contains(["required", "optional"], var.metadata_options.http_tokens)
    error_message = "http_tokens must be either 'required' or 'optional'"
  }

  validation {
    condition     = var.metadata_options.http_put_response_hop_limit >= 1 && var.metadata_options.http_put_response_hop_limit <= 64
    error_message = "http_put_response_hop_limit must be between 1 and 64"
  }

  validation {
    condition     = contains(["enabled", "disabled"], var.metadata_options.instance_metadata_tags)
    error_message = "instance_metadata_tags must be either 'enabled' or 'disabled'"
  }
} 