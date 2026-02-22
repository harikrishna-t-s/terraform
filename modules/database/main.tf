# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name        = "${local.naming.rds}-subnet-group"
  description = "Subnet group for RDS instance"
  subnet_ids  = var.private_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${local.naming.rds}-subnet-group"
    }
  )
}

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  name        = "${local.naming.rds}-parameter-group"
  family      = var.parameter_group_config.family
  description = var.parameter_group_config.description

  dynamic "parameter" {
    for_each = var.parameter_group_config.parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.naming.rds}-parameter-group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# RDS Option Group
resource "aws_db_option_group" "main" {
  name                     = "${local.naming.rds}-option-group"
  option_group_description = var.option_group_config.description
  engine_name              = var.option_group_config.engine_name
  major_engine_version     = var.option_group_config.major_engine_version

  dynamic "option" {
    for_each = var.option_group_config.options
    content {
      option_name = option.value.option_name
      port        = option.value.port
      version     = option.value.version

      vpc_security_group_memberships = option.value.vpc_security_group_memberships
      db_security_group_memberships  = option.value.db_security_group_memberships

      dynamic "option_settings" {
        for_each = option.value.option_settings != null ? option.value.option_settings : []
        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.naming.rds}-option-group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Generate a random password if not provided
resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Call the Secrets Management Module
module "secrets_management" {
  source = "../secrets_management"

  secret_name        = var.secrets_manager_config.secret_name != null ? var.secrets_manager_config.secret_name : "${local.naming.rds}-credentials"
  description        = var.secrets_manager_config.description
  recovery_window_in_days = var.secrets_manager_config.recovery_window_in_days
  rotation_enabled   = var.secrets_manager_config.rotation_enabled
  rotation_lambda_config = var.rotation_lambda_config
  db_username        = var.db_username
  db_password        = random_password.db_password.result
  engine             = var.engine
  host               = aws_db_instance.main.address
  port               = aws_db_instance.main.port
  dbname             = var.db_name
  tags               = merge(var.tags, var.secrets_manager_config.tags, { Name = "${local.naming.rds}-credentials" })
}

# Call the Monitoring Module
module "monitoring" {
  source = "../monitoring"

  rds_instance_id = aws_db_instance.main.id
  rds_instance_arn = aws_db_instance.main.arn
  rds_instance_name = aws_db_instance.main.identifier
  tags = var.tags
}

# IAM Roles for Database Authentication
resource "aws_iam_role" "db_auth" {
  for_each = var.iam_authentication_config.enabled ? { for role in var.iam_authentication_config.iam_roles : role.name => role } : {}

  name        = "${local.naming.rds}-${each.value.name}"
  description = each.value.description

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = "${local.naming.rds}-${each.value.name}"
    }
  )
}

resource "aws_iam_role_policy" "db_auth" {
  for_each = var.iam_authentication_config.enabled ? { for role in var.iam_authentication_config.iam_roles : role.name => role } : {}

  name = "${local.naming.rds}-${each.value.name}-policy"
  role = aws_iam_role.db_auth[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow"
          Action = [
            "rds-db:connect"
          ]
          Resource = [
            "arn:aws:rds-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.main.resource_id}/${var.iam_authentication_config.db_user_prefix}${each.value.name}"
          ]
        }
      ]
    )
  })
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${local.naming.rds}-instance"
  engine = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class
  allocated_storage = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type = var.storage_type
  storage_encrypted = var.storage_encrypted
  kms_key_id = var.storage_encrypted ? aws_kms_key.rds.arn : null
  db_name = var.db_name
  username = var.db_username
  password = random_password.db_password.result
  parameter_group_name = aws_db_parameter_group.main.name
  option_group_name = aws_db_option_group.main.name
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.vpc_security_group_ids
  backup_retention_period = var.backup_retention_period
  backup_window = var.backup_window
  maintenance_window = var.maintenance_window
  multi_az = var.multi_az
  publicly_accessible = var.publicly_accessible
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = var.final_snapshot_identifier
  deletion_protection = var.deletion_protection
  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately = var.apply_immediately
  copy_tags_to_snapshot = var.copy_tags_to_snapshot
  delete_automated_backups = var.delete_automated_backups
  iam_database_authentication_enabled = var.iam_authentication_config.enabled
  tags = merge(
    var.tags,
    {
      Name = "${local.naming.rds}-instance"
    }
  )
}

# KMS Key for RDS Encryption
resource "aws_kms_key" "rds" {
  count = var.storage_encrypted ? 1 : 0

  description = "KMS key for RDS encryption"
  enable_key_rotation = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${local.naming.rds}-kms-key"
    }
  )
}

resource "aws_kms_alias" "rds" {
  count = var.storage_encrypted ? 1 : 0

  name = "alias/${local.naming.rds}-kms-key"
  target_key_id = aws_kms_key.rds[0].key_id
}

# IAM Role for RDS Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${local.naming.rds}-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${local.naming.rds}-monitoring-role"
    }
  )
}

# IAM Policy for RDS Monitoring
resource "aws_iam_role_policy" "rds_monitoring" {
  name = "${local.naming.rds}-monitoring-policy"
  role = aws_iam_role.rds_monitoring.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:PutRetentionPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

# RDS Read Replicas
resource "aws_db_instance" "read_replicas" {
  for_each = var.read_replica_config.enabled ? { for replica in var.read_replica_config.replicas : replica.identifier => replica } : {}

  identifier = "${local.naming.rds}-${each.value.identifier}"
  replicate_source_db = aws_db_instance.main.identifier
  instance_class = each.value.instance_class
  allocated_storage = each.value.allocated_storage
  storage_type = each.value.storage_type
  storage_encrypted = each.value.storage_encrypted
  kms_key_id = each.value.storage_encrypted ? aws_kms_key.rds[0].arn : null
  publicly_accessible = each.value.publicly_accessible
  vpc_security_group_ids = each.value.vpc_security_group_ids
  db_subnet_group_name = aws_db_subnet_group.main.name
  monitoring_interval = each.value.monitoring_interval
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  enabled_cloudwatch_logs_exports = each.value.enabled_cloudwatch_logs_exports
  auto_minor_version_upgrade = each.value.auto_minor_version_upgrade
  apply_immediately = each.value.apply_immediately
  copy_tags_to_snapshot = each.value.copy_tags_to_snapshot
  deletion_protection = each.value.deletion_protection
  performance_insights_enabled = each.value.performance_insights_enabled
  performance_insights_retention_period = each.value.performance_insights_retention_period
  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = "${local.naming.rds}-${each.value.identifier}"
    }
  )
}

# Call the Monitoring Module for Read Replicas
module "read_replica_monitoring" {
  for_each = var.read_replica_config.enabled ? { for replica in var.read_replica_config.replicas : replica.identifier => replica } : {}
  source = "../monitoring"

  rds_instance_id = aws_db_instance.read_replicas[each.key].id
  rds_instance_arn = aws_db_instance.read_replicas[each.key].arn
  rds_instance_name = aws_db_instance.read_replicas[each.key].identifier
  tags = merge(var.tags, each.value.tags)
} 