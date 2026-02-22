# VPC and Network Configuration
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ALB"
  type        = list(string)
}

variable "internal" {
  description = "Whether the ALB is internal"
  type        = bool
  default     = false
}

# Security Configuration
variable "http_allowed_cidr_blocks" {
  description = "Map of CIDR blocks allowed to access the ALB on HTTP port"
  type        = map(string)
  default     = {
    "internet" = "0.0.0.0/0"
  }
}

variable "https_allowed_cidr_blocks" {
  description = "Map of CIDR blocks allowed to access the ALB on HTTPS port"
  type        = map(string)
  default     = {
    "internet" = "0.0.0.0/0"
  }
}

variable "http_allowed_ipv6_cidr_blocks" {
  description = "List of IPv6 CIDR blocks allowed to access the ALB on HTTP port"
  type        = list(string)
  default     = ["::/0"]
}

variable "https_allowed_ipv6_cidr_blocks" {
  description = "List of IPv6 CIDR blocks allowed to access the ALB on HTTPS port"
  type        = list(string)
  default     = ["::/0"]
}

variable "app_security_group_id" {
  description = "ID of the application security group"
  type        = string
}

# Target Group Configuration
variable "target_port" {
  description = "Port on which targets receive traffic"
  type        = number
  default     = 8080
  validation {
    condition     = var.target_port >= 1 && var.target_port <= 65535
    error_message = "Target port must be between 1 and 65535."
  }
}

variable "target_protocol" {
  description = "Protocol to use for routing traffic to the targets"
  type        = string
  default     = "HTTP"
  validation {
    condition     = contains(["HTTP", "HTTPS"], var.target_protocol)
    error_message = "Target protocol must be either HTTP or HTTPS."
  }
}

# Health Check Configuration
variable "health_check" {
  description = "Health check configuration"
  type = object({
    enabled             = bool
    healthy_threshold   = number
    interval            = number
    matcher            = string
    path               = string
    port               = number
    protocol           = string
    timeout            = number
    unhealthy_threshold = number
  })
  default = {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher            = "200"
    path               = "/health"
    port               = 8080
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 2
  }
  validation {
    condition     = var.health_check.healthy_threshold >= 1 && var.health_check.healthy_threshold <= 10
    error_message = "Healthy threshold must be between 1 and 10."
  }
  validation {
    condition     = var.health_check.interval >= 5 && var.health_check.interval <= 300
    error_message = "Health check interval must be between 5 and 300 seconds."
  }
  validation {
    condition     = var.health_check.timeout >= 2 && var.health_check.timeout <= 60
    error_message = "Health check timeout must be between 2 and 60 seconds."
  }
  validation {
    condition     = var.health_check.unhealthy_threshold >= 1 && var.health_check.unhealthy_threshold <= 10
    error_message = "Unhealthy threshold must be between 1 and 10."
  }
}

# Stickiness Configuration
variable "stickiness" {
  description = "Stickiness configuration"
  type = object({
    enabled         = bool
    cookie_duration = number
    type           = string
  })
  default = {
    enabled         = true
    cookie_duration = 86400
    type           = "lb_cookie"
  }
  validation {
    condition     = var.stickiness.cookie_duration >= 1 && var.stickiness.cookie_duration <= 604800
    error_message = "Cookie duration must be between 1 and 604800 seconds."
  }
}

# SSL Configuration
variable "certificate_arn" {
  description = "ARN of the default SSL server certificate"
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-2016-08"
}

# Monitoring Configuration
variable "sns_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms"
  type        = string
}

variable "http_5xx_error_threshold" {
  description = "Threshold for HTTP 5XX errors alarm"
  type        = number
  default     = 10
}

variable "target_response_time_threshold" {
  description = "Threshold for target response time alarm (seconds)"
  type        = number
  default     = 5
}

# Logging Configuration
variable "alb_logs_bucket_id" {
  description = "ID of the S3 bucket for ALB logs"
  type        = string
}

# Protection Configuration
variable "enable_deletion_protection" {
  description = "Whether to enable deletion protection"
  type        = bool
  default     = true
}

# Environment and Tagging
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

variable "allowed_cidr_blocks" {
  description = "List of allowed CIDR blocks with protocol and description"
  type = list(object({
    protocol    = string
    cidr_block  = string
    description = string
    port        = number
  }))
  default = [
    {
      protocol    = "http"
      cidr_block  = "0.0.0.0/0"
      description = "HTTP from internet"
      port        = 80
    },
    {
      protocol    = "https"
      cidr_block  = "0.0.0.0/0"
      description = "HTTPS from internet"
      port        = 443
    }
  ]
}

variable "allowed_ipv6_cidr_blocks" {
  description = "List of allowed IPv6 CIDR blocks with protocol and description"
  type = list(object({
    protocol    = string
    cidr_block  = string
    description = string
    port        = number
  }))
  default = [
    {
      protocol    = "http"
      cidr_block  = "::/0"
      description = "HTTP from IPv6 internet"
      port        = 80
    },
    {
      protocol    = "https"
      cidr_block  = "::/0"
      description = "HTTPS from IPv6 internet"
      port        = 443
    }
  ]
}

variable "listeners" {
  description = "Map of listener configurations"
  type = map(object({
    port     = number
    protocol = string
    ssl_policy = optional(string)
    certificate_arn = optional(string)
    default_action = object({
      type = string
      target_group_arn = optional(string)
      redirect = optional(object({
        port        = string
        protocol    = string
        status_code = string
      }))
    })
  }))
  default = {
    http = {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type = "redirect"
        redirect = {
          port        = "443"
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      }
    }
    https = {
      port     = 443
      protocol = "HTTPS"
      ssl_policy = "ELBSecurityPolicy-2016-08"
      certificate_arn = null
      default_action = {
        type = "forward"
        target_group_arn = null
      }
    }
  }
}

variable "waf_rules" {
  description = "Map of WAF rules to apply to the ALB"
  type = map(object({
    name        = string
    priority    = number
    action      = string
    statement = object({
      managed_rule_group = optional(object({
        name        = string
        vendor_name = string
        excluded_rules = optional(list(string))
      }))
      rate_based = optional(object({
        limit              = number
        aggregate_key_type = string
        scope_down = optional(object({
          ip_set_reference_statement = optional(object({
            arn = string
          }))
        })
      }))
      ip_set_reference = optional(object({
        arn = string
      }))
    })
    visibility_config = object({
      cloudwatch_metrics_enabled = bool
      metric_name               = string
      sampled_requests_enabled  = bool
    })
  }))
  default = {
    aws_common_rules = {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 1
      action   = "none"
      statement = {
        managed_rule_group = {
          name        = "AWSManagedRulesCommonRuleSet"
          vendor_name = "AWS"
        }
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name               = "AWSManagedRulesCommonRuleSetMetric"
        sampled_requests_enabled  = true
      }
    }
    aws_bad_inputs = {
      name     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority = 2
      action   = "none"
      statement = {
        managed_rule_group = {
          name        = "AWSManagedRulesKnownBadInputsRuleSet"
          vendor_name = "AWS"
        }
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name               = "AWSManagedRulesKnownBadInputsRuleSetMetric"
        sampled_requests_enabled  = true
      }
    }
  }
}

variable "waf_default_action" {
  description = "Default action for WAF Web ACL"
  type        = string
  default     = "allow"
  validation {
    condition     = contains(["allow", "block"], var.waf_default_action)
    error_message = "WAF default action must be either 'allow' or 'block'."
  }
}

variable "waf_visibility_config" {
  description = "Visibility configuration for WAF Web ACL"
  type = object({
    cloudwatch_metrics_enabled = bool
    metric_name               = string
    sampled_requests_enabled  = bool
  })
  default = {
    cloudwatch_metrics_enabled = true
    metric_name               = "WAFWebACLMetric"
    sampled_requests_enabled  = true
  }
}

variable "listener_rules" {
  description = "Map of listener rules for path-based and host-based routing"
  type = map(object({
    listener_key = string
    priority     = number
    action = object({
      type             = string
      target_group_arn = optional(string)
      fixed_response = optional(object({
        content_type = string
        message_body = optional(string)
        status_code  = string
      }))
      redirect = optional(object({
        host        = optional(string)
        path        = optional(string)
        port        = optional(string)
        protocol    = optional(string)
        query       = optional(string)
        status_code = string
      }))
    })
    condition = object({
      host_header = optional(object({
        values = list(string)
      }))
      path_pattern = optional(object({
        values = list(string)
      }))
      http_header = optional(object({
        http_header_name = string
        values          = list(string)
      }))
      http_request_method = optional(object({
        values = list(string)
      }))
      query_string = optional(object({
        key   = optional(string)
        value = string
      }))
      source_ip = optional(object({
        values = list(string)
      }))
    })
  }))
  default = {}
}

variable "target_group_attachments" {
  description = "Map of target group attachments to register with the target group"
  type = map(object({
    target_id        = string
    port             = optional(number)
    availability_zone = optional(string)
  }))
  default = {}
}

variable "target_group_attachment_port" {
  description = "Port to use for target group attachments if not specified in the attachment"
  type        = number
  default     = null
}

variable "target_group_attachment_availability_zone" {
  description = "Availability zone to use for target group attachments if not specified in the attachment"
  type        = string
  default     = null
} 