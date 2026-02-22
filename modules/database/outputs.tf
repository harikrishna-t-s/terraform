# RDS Instance Information
output "db_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = aws_db_instance.main.address
}

output "db_instance_endpoint" {
  description = "The connection endpoint of the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_name" {
  description = "The database name"
  value       = aws_db_instance.main.name
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "db_instance_port" {
  description = "The database port"
  value       = aws_db_instance.main.port
}

# Security Group Information
output "db_security_group_id" {
  description = "The security group ID of the RDS instance"
  value       = aws_security_group.rds.id
}

# Subnet Group Information
output "db_subnet_group_id" {
  description = "The db subnet group name"
  value       = aws_db_subnet_group.main.id
}

# Monitoring Information
output "db_monitoring_role_arn" {
  description = "The ARN of the IAM role for RDS monitoring"
  value       = aws_iam_role.rds_monitoring.arn
}

# CloudWatch Alarm Information
output "cloudwatch_alarm_ids" {
  description = "Map of CloudWatch alarm IDs"
  value = {
    cpu_utilization     = aws_cloudwatch_metric_alarm.cpu_utilization.id
    free_storage_space  = aws_cloudwatch_metric_alarm.free_storage_space.id
    database_connections = aws_cloudwatch_metric_alarm.database_connections.id
  }
}

# KMS Key Information
output "kms_key_id" {
  description = "The ID of the KMS key used for RDS encryption"
  value       = var.kms_config.create_key ? aws_kms_key.rds[0].key_id : null
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for RDS encryption"
  value       = var.kms_config.create_key ? aws_kms_key.rds[0].arn : null
}

# CloudWatch Alarm Outputs
output "alarm_arns" {
  description = "Map of all CloudWatch alarm ARNs"
  value = {
    cpu_utilization     = try(aws_cloudwatch_metric_alarm.cpu_utilization[0].arn, null)
    free_storage_space  = try(aws_cloudwatch_metric_alarm.free_storage_space[0].arn, null)
    database_connections = try(aws_cloudwatch_metric_alarm.database_connections[0].arn, null)
    read_latency        = try(aws_cloudwatch_metric_alarm.read_latency[0].arn, null)
    write_latency       = try(aws_cloudwatch_metric_alarm.write_latency[0].arn, null)
    read_iops           = try(aws_cloudwatch_metric_alarm.read_iops[0].arn, null)
    write_iops          = try(aws_cloudwatch_metric_alarm.write_iops[0].arn, null)
  }
}

output "alarm_names" {
  description = "Map of all CloudWatch alarm names"
  value = {
    cpu_utilization     = try(aws_cloudwatch_metric_alarm.cpu_utilization[0].alarm_name, null)
    free_storage_space  = try(aws_cloudwatch_metric_alarm.free_storage_space[0].alarm_name, null)
    database_connections = try(aws_cloudwatch_metric_alarm.database_connections[0].alarm_name, null)
    read_latency        = try(aws_cloudwatch_metric_alarm.read_latency[0].alarm_name, null)
    write_latency       = try(aws_cloudwatch_metric_alarm.write_latency[0].alarm_name, null)
    read_iops           = try(aws_cloudwatch_metric_alarm.read_iops[0].alarm_name, null)
    write_iops          = try(aws_cloudwatch_metric_alarm.write_iops[0].alarm_name, null)
  }
}

# Storage Auto-Scaling Information
output "storage_autoscaling_enabled" {
  description = "Whether storage auto-scaling is enabled"
  value       = var.storage_config.auto_scaling.enabled
}

output "storage_autoscaling_config" {
  description = "Storage auto-scaling configuration"
  value = var.storage_config.auto_scaling.enabled ? {
    min_storage_size = var.storage_config.auto_scaling.min_storage_size
    max_storage_size = var.storage_config.auto_scaling.max_storage_size
    target_percent   = var.storage_config.auto_scaling.target_percent
    scale_in_cooldown  = var.storage_config.auto_scaling.scale_in_cooldown
    scale_out_cooldown = var.storage_config.auto_scaling.scale_out_cooldown
  } : null
}

output "storage_autoscaling_alarm_arn" {
  description = "ARN of the CloudWatch alarm for storage auto-scaling"
  value       = try(aws_cloudwatch_metric_alarm.storage_autoscaling[0].arn, null)
}

# Secrets Manager Outputs
output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = try(aws_secretsmanager_secret.db_credentials[0].arn, null)
}

output "secret_name" {
  description = "Name of the Secrets Manager secret containing database credentials"
  value       = try(aws_secretsmanager_secret.db_credentials[0].name, null)
}

output "secret_rotation_enabled" {
  description = "Whether secret rotation is enabled"
  value       = try(aws_secretsmanager_secret_rotation.db_credentials[0].id != null, false)
}

# Read Replica Outputs
output "read_replica_ids" {
  description = "List of read replica instance IDs"
  value       = var.read_replica_config.enabled ? aws_db_instance.read_replicas[*].id : []
}

output "read_replica_endpoints" {
  description = "List of read replica endpoints"
  value       = var.read_replica_config.enabled ? aws_db_instance.read_replicas[*].endpoint : []
}

output "read_replica_arns" {
  description = "List of read replica ARNs"
  value       = var.read_replica_config.enabled ? aws_db_instance.read_replicas[*].arn : []
}

output "read_replica_status" {
  description = "List of read replica statuses"
  value       = var.read_replica_config.enabled ? aws_db_instance.read_replicas[*].status : []
}

output "read_replica_replication_lag_alarms" {
  description = "Map of read replica replication lag alarm ARNs"
  value       = var.read_replica_config.enabled ? { for idx, alarm in aws_cloudwatch_metric_alarm.replica_replication_lag : idx => alarm.arn } : {}
}

# Parameter Group Outputs
output "parameter_group_id" {
  description = "The ID of the parameter group"
  value       = aws_db_parameter_group.main.id
}

output "parameter_group_arn" {
  description = "The ARN of the parameter group"
  value       = aws_db_parameter_group.main.arn
}

output "parameter_group_family" {
  description = "The family of the parameter group"
  value       = aws_db_parameter_group.main.family
}

output "parameter_group_parameters" {
  description = "Map of parameter names and values"
  value       = var.parameter_group_config.parameters
  sensitive   = true
}

# Option Group Outputs
output "option_group_id" {
  description = "The ID of the option group"
  value       = aws_db_option_group.main.id
}

output "option_group_arn" {
  description = "The ARN of the option group"
  value       = aws_db_option_group.main.arn
}

output "option_group_name" {
  description = "The name of the option group"
  value       = aws_db_option_group.main.name
}

# Enhanced Monitoring Outputs
output "enhanced_monitoring_role_arn" {
  description = "The ARN of the IAM role for enhanced monitoring"
  value       = var.enhanced_monitoring_config.enabled ? aws_iam_role.enhanced_monitoring[0].arn : null
}

output "enhanced_monitoring_interval" {
  description = "The interval in seconds between points when enhanced monitoring metrics are collected"
  value       = var.enhanced_monitoring_config.enabled ? var.enhanced_monitoring_config.interval : null
}

# Performance Insights Outputs
output "performance_insights_enabled" {
  description = "Whether Performance Insights is enabled"
  value       = var.performance_insights_config.enabled
}

output "performance_insights_retention_period" {
  description = "The amount of time in days to retain Performance Insights data"
  value       = var.performance_insights_config.enabled ? var.performance_insights_config.retention_period : null
}

# IAM Authentication Outputs
output "iam_authentication_enabled" {
  description = "Whether IAM database authentication is enabled"
  value       = var.iam_authentication_config.enabled
}

output "iam_role_arns" {
  description = "Map of IAM role ARNs for database authentication"
  value       = var.iam_authentication_config.enabled ? { for k, v in aws_iam_role.db_auth : k => v.arn } : {}
}

output "iam_role_names" {
  description = "Map of IAM role names for database authentication"
  value       = var.iam_authentication_config.enabled ? { for k, v in aws_iam_role.db_auth : k => v.name } : {}
}

output "db_auth_users" {
  description = "Map of database users for IAM authentication"
  value       = var.iam_authentication_config.enabled ? { for role in var.iam_authentication_config.iam_roles : role.name => "${var.iam_authentication_config.db_user_prefix}${role.name}" } : {}
}

output "rotation_lambda_arn" {
  description = "The ARN of the Lambda function used for secret rotation"
  value       = var.rotation_lambda_config.create_lambda ? aws_lambda_function.rotation[0].arn : null
}

output "rotation_lambda_role_arn" {
  description = "The ARN of the IAM role used by the rotation Lambda function"
  value       = var.rotation_lambda_config.create_lambda ? aws_iam_role.rotation_lambda[0].arn : null
} 