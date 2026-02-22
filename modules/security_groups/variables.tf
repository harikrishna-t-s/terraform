# VPC Configuration
variable "vpc_id" {
  description = "ID of the VPC where security groups will be created"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  type        = string
}

# Environment and Tagging
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ALB Configuration
variable "alb_ingress_cidr_blocks" {
  description = "Map of CIDR blocks allowed to access the ALB"
  type        = map(string)
  default     = {
    "internet" = "0.0.0.0/0"
  }
}

variable "alb_ingress_ipv6_cidr_blocks" {
  description = "List of IPv6 CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["::/0"]
}

# Application Configuration
variable "app_port" {
  description = "Port on which the application listens for incoming traffic"
  type        = number
  default     = 8080
  validation {
    condition     = var.app_port >= 1 && var.app_port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}

# Bastion Configuration
variable "bastion_ingress_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the bastion host"
  type        = list(string)
  default     = []
}

# Database Configuration
variable "db_port" {
  description = "Port on which the database listens for incoming traffic"
  type        = number
  default     = 5432
  validation {
    condition     = var.db_port >= 1 && var.db_port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}

# ElastiCache Configuration
variable "elasticache_port" {
  description = "Port on which ElastiCache listens for incoming traffic"
  type        = number
  default     = 6379
  validation {
    condition     = var.elasticache_port >= 1 && var.elasticache_port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}

# OpenSearch Configuration
variable "opensearch_port" {
  description = "Port on which OpenSearch listens for incoming traffic"
  type        = number
  default     = 9200
  validation {
    condition     = var.opensearch_port >= 1 && var.opensearch_port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}

# Name Prefix Configuration
variable "name_prefix" {
  description = "Prefix to use for resource names"
  type        = string
  default     = ""
}

# Security Group Rules Configuration
variable "enable_alb_http" {
  description = "Whether to enable HTTP access to ALB"
  type        = bool
  default     = true
}

variable "enable_alb_https" {
  description = "Whether to enable HTTPS access to ALB"
  type        = bool
  default     = true
}

variable "enable_app_ssh" {
  description = "Whether to enable SSH access to application servers"
  type        = bool
  default     = true
}

variable "enable_db_postgres" {
  description = "Whether to enable PostgreSQL access to database"
  type        = bool
  default     = true
}

variable "enable_db_mysql" {
  description = "Whether to enable MySQL access to database"
  type        = bool
  default     = false
}

variable "enable_redis" {
  description = "Whether to enable Redis security group"
  type        = bool
  default     = false
}

variable "enable_elasticsearch" {
  description = "Whether to enable Elasticsearch security group"
  type        = bool
  default     = false
}

variable "enable_vpc_endpoints" {
  description = "Whether to enable VPC endpoints security group"
  type        = bool
  default     = false
} 