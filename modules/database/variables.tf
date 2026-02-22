# Data sources for IAM policies
data "aws_iam_policy_document" "rds_monitoring" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/rds/*"]
  }
}

data "aws_iam_policy_document" "rds_secrets_access" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = ["arn:aws:secretsmanager:*:*:secret:${local.naming.secrets}-*"]
  }
}

# Core Configuration
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.db_name))
    error_message = "Database name must contain only lowercase letters, numbers, and hyphens."
  }
}

# Network Configuration
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC ID."
  }
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least two subnets are required for high availability."
  }
}

variable "db_security_group_id" {
  description = "ID of the database security group"
  type        = string
  validation {
    condition     = can(regex("^sg-[a-z0-9]+$", var.db_security_group_id))
    error_message = "Security group ID must be a valid AWS security group ID."
  }
}

# Engine Configuration
variable "engine" {
  description = "The database engine to use"
  type        = string
  default     = "postgres"
  validation {
    condition     = contains(["postgres", "mysql", "mariadb"], var.engine)
    error_message = "Engine must be one of: postgres, mysql, mariadb."
  }
}

variable "engine_version" {
  description = "The engine version to use"
  type        = string
  default     = "14.7"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.engine_version))
    error_message = "Engine version must be in the format 'X.Y'."
  }
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t3.micro"
  validation {
    condition     = can(regex("^db\\.[a-z0-9]+\\.(micro|small|medium|large|xlarge|2xlarge|4xlarge|8xlarge|16xlarge)$", var.instance_class))
    error_message = "Invalid RDS instance class format."
  }
}

# Storage Configuration
variable "storage_config" {
  description = "Configuration for RDS storage and auto-scaling"
  type = object({
    allocated_storage = optional(number, 20)
    max_allocated_storage = optional(number, 100)
    storage_type = optional(string, "gp3")
    iops = optional(number, null)
    storage_throughput = optional(number, null)
    auto_scaling = optional(object({
      enabled = optional(bool, true)
      min_storage_size = optional(number, 20)
      max_storage_size = optional(number, 100)
      target_percent = optional(number, 75)
      scale_in_cooldown = optional(number, 300)
      scale_out_cooldown = optional(number, 300)
    }))
  })
  default = {}
  validation {
    condition     = var.storage_config.allocated_storage <= var.storage_config.max_allocated_storage
    error_message = "allocated_storage must be less than or equal to max_allocated_storage"
  }
}

# Backup Configuration
variable "backup_config" {
  description = "Configuration for RDS backups"
  type = object({
    retention_period = optional(number, 7)
    window = optional(string, "03:00-04:00")
    copy_tags = optional(bool, true)
    delete_automated_backups = optional(bool, true)
  })
  default = {}
  validation {
    condition     = var.backup_config.retention_period >= 0
    error_message = "Backup retention period must be a non-negative number."
  }
}

# Maintenance Configuration
variable "maintenance_config" {
  description = "Configuration for RDS maintenance"
  type = object({
    window = optional(string, "Mon:04:00-Mon:05:00")
    auto_minor_version_upgrade = optional(bool, true)
    allow_major_version_upgrade = optional(bool, false)
  })
  default = {}
}

# Monitoring Configuration
variable "monitoring_config" {
  description = "Configuration for RDS monitoring"
  type = object({
    interval = optional(number, 60)
    role_arn = optional(string, null)
    performance_insights = optional(object({
      enabled = optional(bool, true)
      retention_period = optional(number, 7)
    }))
    enhanced_monitoring = optional(object({
      enabled = optional(bool, true)
      metrics = optional(list(string), ["cpu", "disk", "memory", "network"])
    }))
  })
  default = {}
  validation {
    condition     = var.monitoring_config.interval >= 0
    error_message = "Monitoring interval must be a non-negative number."
  }
}

# CloudWatch Alarm Configuration
variable "alarm_config" {
  description = "Configuration for CloudWatch alarms"
  type = object({
    cpu_utilization = optional(object({
      threshold = optional(number, 80)
      evaluation_periods = optional(number, 2)
      period = optional(number, 300)
      statistic = optional(string, "Average")
      alarm_actions = optional(list(string), [])
      ok_actions = optional(list(string), [])
      treat_missing_data = optional(string, "missing")
    }))
    free_storage_space = optional(object({
      threshold = optional(number, 10000000000) # 10GB
      evaluation_periods = optional(number, 2)
      period = optional(number, 300)
      statistic = optional(string, "Average")
      alarm_actions = optional(list(string), [])
      ok_actions = optional(list(string), [])
      treat_missing_data = optional(string, "missing")
    }))
    database_connections = optional(object({
      threshold = optional(number, 1000)
      evaluation_periods = optional(number, 2)
      period = optional(number, 300)
      statistic = optional(string, "Average")
      alarm_actions = optional(list(string), [])
      ok_actions = optional(list(string), [])
      treat_missing_data = optional(string, "missing")
    }))
  })
  default = {}
}

# Security Configuration
variable "security_config" {
  description = "Configuration for RDS security"
  type = object({
    deletion_protection = optional(bool, true)
    publicly_accessible = optional(bool, false)
    skip_final_snapshot = optional(bool, false)
    final_snapshot_identifier = optional(string, null)
    kms_key_arn = optional(string, null)
    iam_authentication = optional(object({
      enabled = optional(bool, false)
      iam_roles = optional(list(object({
        name = string
        description = string
        tags = optional(map(string), {})
      })), [])
    }))
  })
  default = {}
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# Dependencies
variable "db_instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t3.micro"
  validation {
    condition     = can(regex("^db\\.[a-z0-9]+\\.(micro|small|medium|large|xlarge|2xlarge|4xlarge|8xlarge|16xlarge)$", var.db_instance_class))
    error_message = "Invalid RDS instance class format."
  }
}

variable "db_engine_version" {
  description = "The engine version to use"
  type        = string
  default     = "14.7"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.db_engine_version))
    error_message = "Engine version must be in the format 'X.Y'."
  }
}

variable "db_username" {
  description = "Username for the master DB user"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_]+$", var.db_username))
    error_message = "Username must contain only alphanumeric characters and underscores."
  }
}

variable "db_password" {
  description = "Password for the master DB user"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Password must be at least 8 characters long."
  }
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
  type        = string
  default     = null
  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]+:key/[a-z0-9-]+$", var.kms_key_arn))
    error_message = "KMS key ARN must be a valid AWS KMS key ARN."
  }
}

variable "monitoring_role_arn" {
  description = "ARN of the IAM role for monitoring"
  type        = string
  default     = null
  validation {
    condition     = var.monitoring_role_arn == null || can(regex("^arn:aws:iam:[a-z0-9-]+:[0-9]+:role/[a-zA-Z0-9_-]+$", var.monitoring_role_arn))
    error_message = "Monitoring role ARN must be a valid AWS IAM role ARN."
  }
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for alarms"
  type        = string
  default     = null
  validation {
    condition     = var.sns_topic_arn == null || can(regex("^arn:aws:sns:[a-z0-9-]+:[0-9]+:[a-zA-Z0-9_-]+$", var.sns_topic_arn))
    error_message = "SNS topic ARN must be a valid AWS SNS topic ARN."
  }
}

variable "database_name" {
  description = "Name of the database"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.database_name))
    error_message = "Database name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "database_username" {
  description = "Username for the master DB user"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_]+$", var.database_username))
    error_message = "Username must contain only alphanumeric characters and underscores."
  }
}

variable "database_password" {
  description = "Password for the master DB user"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.database_password) >= 8
    error_message = "Password must be at least 8 characters long."
  }
}

variable "database_port" {
  description = "Port for the database"
  type        = number
  default     = 5432
  validation {
    condition     = var.database_port >= 1 && var.database_port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}

variable "database_subnet_ids" {
  description = "List of subnet IDs for the database"
  type        = list(string)
  validation {
    condition     = length(var.database_subnet_ids) >= 2
    error_message = "At least two subnets are required for high availability."
  }
}

variable "app_security_group_id" {
  description = "ID of the application security group"
  type        = string
  validation {
    condition     = can(regex("^sg-[a-z0-9]+$", var.app_security_group_id))
    error_message = "Security group ID must be a valid AWS security group ID."
  }
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "The number of days to retain backups for"
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_period >= 0
    error_message = "Backup retention period must be a non-negative number."
  }
}

variable "backup_window" {
  description = "The daily time range during which backups happen"
  type        = string
  default     = "03:00-04:00"
  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]-([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.backup_window))
    error_message = "Backup window must be in the format 'HH:MM-HH:MM'."
  }
}

variable "maintenance_window" {
  description = "The window to perform maintenance in"
  type        = string
  default     = "Mon:04:00-Mon:05:00"
  validation {
    condition     = can(regex("^[A-Za-z]{3}:[0-1][0-9]:[0-5][0-9]-[A-Za-z]{3}:[0-1][0-9]:[0-5][0-9]$", var.maintenance_window))
    error_message = "Maintenance window must be in the format 'DDD:HH:MM-DDD:HH:MM'."
  }
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected"
  type        = number
  default     = 60
  validation {
    condition     = var.monitoring_interval >= 0
    error_message = "Monitoring interval must be a non-negative number."
  }
}

variable "performance_insights_retention_period" {
  description = "The amount of time in days to retain Performance Insights data"
  type        = number
  default     = 7
  validation {
    condition     = var.performance_insights_retention_period >= 0
    error_message = "Performance insights retention period must be a non-negative number."
  }
}

variable "cpu_utilization_threshold" {
  description = "The threshold for CPU utilization alarm"
  type        = number
  default     = 80
  validation {
    condition     = var.cpu_utilization_threshold >= 0 && var.cpu_utilization_threshold <= 100
    error_message = "CPU utilization threshold must be between 0 and 100."
  }
}

variable "free_storage_space_threshold" {
  description = "The threshold for free storage space alarm"
  type        = number
  default     = 10000000000 # 10GB
  validation {
    condition     = var.free_storage_space_threshold >= 0
    error_message = "Free storage space threshold must be a non-negative number."
  }
}

variable "database_connections_threshold" {
  description = "The threshold for database connections alarm"
  type        = number
  default     = 1000
  validation {
    condition     = var.database_connections_threshold >= 0
    error_message = "Database connections threshold must be a non-negative number."
  }
}

variable "deletion_protection" {
  description = "Specifies if the RDS instance is protected from deletion"
  type        = bool
  default     = true
}

variable "alarm_config" {
  description = "Configuration for CloudWatch alarms"
  type = object({
    cpu_utilization = optional(object({
      threshold = optional(number, 80)
      evaluation_periods = optional(number, 2)
      period = optional(number, 300)
      statistic = optional(string, "Average")
      alarm_actions = optional(list(string), [])
      ok_actions = optional(list(string), [])
      treat_missing_data = optional(string, "missing")
    }))
    free_storage_space = optional(object({
      threshold = optional(number, 10000000000) # 10GB
      evaluation_periods = optional(number, 2)
      period = optional(number, 300)
      statistic = optional(string, "Average")
      alarm_actions = optional(list(string), [])
      ok_actions = optional(list(string), [])
      treat_missing_data = optional(string, "missing")
    }))
    database_connections = optional(object({
      threshold = optional(number, 1000)
      evaluation_periods = optional(number, 2)
      period = optional(number, 300)
      statistic = optional(string, "Average")
      alarm_actions = optional(list(string), [])
      ok_actions = optional(list(string), [])
      treat_missing_data = optional(string, "missing")
    }))
  })
  default = {}
}

variable "secrets_manager_config" {
  description = "Configuration for Secrets Manager"
  type = object({
    create_secret = optional(bool, true)
    secret_name = optional(string, null)
    description = optional(string, "RDS credentials")
    recovery_window_in_days = optional(number, 30)
    rotation_enabled = optional(bool, true)
    tags = optional(map(string), {})
  })
  default = {}
}

variable "read_replica_config" {
  description = "Configuration for read replicas"
  type = object({
    enabled = optional(bool, false)
    replicas = optional(list(object({
      identifier = string
      instance_class = string
      allocated_storage = number
      storage_type = string
      storage_encrypted = bool
      publicly_accessible = bool
      vpc_security_group_ids = list(string)
      monitoring_interval = number
      enabled_cloudwatch_logs_exports = list(string)
      auto_minor_version_upgrade = bool
      apply_immediately = bool
      copy_tags_to_snapshot = bool
      deletion_protection = bool
      performance_insights_enabled = bool
      performance_insights_retention_period = number
      tags = map(string)
    })), [])
  })
  default = {}
}

variable "parameter_group_config" {
  description = "Configuration for the parameter group"
  type = object({
    family = string
    description = string
    parameters = map(string)
  })
  default = {
    family = "postgres14"
    description = "Custom parameter group for RDS"
    parameters = {}
}
}

variable "iam_authentication_config" {
  description = "Configuration for IAM authentication"
  type = object({
    enabled = optional(bool, false)
    iam_roles = optional(list(object({
      name = string
      description = string
      tags = optional(map(string), {})
    })), [])
  })
  default = {}
}

variable "kms_config" {
  description = "Configuration for KMS key"
  type = object({
    create_key = optional(bool, true)
    description = optional(string, "KMS key for RDS encryption")
    key_usage = optional(string, "ENCRYPT_DECRYPT")
    customer_master_key_spec = optional(string, "SYMMETRIC_DEFAULT")
    enable_key_rotation = optional(bool, true)
    deletion_window_in_days = optional(number, 7)
    policy = optional(string, null)
    tags = optional(map(string), {})
  })
  default = {}
}

variable "rotation_lambda_config" {
  description = "Configuration for rotation Lambda function"
  type = object({
    create_lambda = optional(bool, true)
    function_name = optional(string, null)
    runtime = optional(string, "python3.9")
    timeout = optional(number, 30)
    memory_size = optional(number, 128)
    environment_variables = optional(map(string), {})
    vpc_config = optional(object({
      subnet_ids = list(string)
      security_group_ids = list(string)
    }))
    tags = optional(map(string), {})
  })
  default = {}
} 
} 