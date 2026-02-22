locals {
  # Naming conventions
  name_prefix = var.environment != "" ? "${var.environment}-" : ""
  
  naming = {
    # Core resources
    rds = "${local.name_prefix}${var.db_name}"
    parameter_group = "${local.name_prefix}${var.db_name}-parameter-group"
    option_group = "${local.name_prefix}${var.db_name}-option-group"
    subnet_group = "${local.name_prefix}${var.db_name}-subnet-group"
    monitoring_role = "${local.name_prefix}${var.db_name}-monitoring-role"
    secrets = "${local.name_prefix}${var.db_name}-credentials"
    
    # Read replicas
    read_replica = "${local.name_prefix}${var.db_name}-replica"
    read_replica_parameter_group = "${local.name_prefix}${var.db_name}-replica-parameter-group"
    
    # IAM resources
    iam_role = "${local.name_prefix}${var.db_name}-role"
    iam_policy = "${local.name_prefix}${var.db_name}-policy"
    
    # CloudWatch resources
    cpu_alarm = "${local.name_prefix}${var.db_name}-cpu-utilization"
    storage_alarm = "${local.name_prefix}${var.db_name}-storage-space"
    connections_alarm = "${local.name_prefix}${var.db_name}-connections"
    replication_lag_alarm = "${local.name_prefix}${var.db_name}-replication-lag"
  }

  # Common tags
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Service     = "database"
      ManagedBy   = "terraform"
      Component   = "rds"
    }
  )

  # Feature flags
  features = {
    iam_auth_enabled = var.security_config.iam_authentication.enabled
    read_replicas_enabled = var.read_replica_config.enabled
    performance_insights_enabled = var.monitoring_config.performance_insights.enabled
    enhanced_monitoring_enabled = var.monitoring_config.enhanced_monitoring.enabled
    storage_autoscaling_enabled = var.storage_config.auto_scaling.enabled
    secrets_manager_enabled = var.secrets_manager_config.create_secret
  }

  # Engine configuration
  engine_config = {
    postgres = {
      family = "postgres${split(".", var.engine_version)[0]}"
      option_group_engine = "postgres"
      major_version = split(".", var.engine_version)[0]
      default_port = 5432
      default_charset = "UTF8"
      default_collation = "en_US.UTF-8"
    }
    mysql = {
      family = "mysql${split(".", var.engine_version)[0]}"
      option_group_engine = "mysql"
      major_version = split(".", var.engine_version)[0]
      default_port = 3306
      default_charset = "utf8mb4"
      default_collation = "utf8mb4_unicode_ci"
    }
    mariadb = {
      family = "mariadb${split(".", var.engine_version)[0]}"
      option_group_engine = "mariadb"
      major_version = split(".", var.engine_version)[0]
      default_port = 3306
      default_charset = "utf8mb4"
      default_collation = "utf8mb4_unicode_ci"
    }
  }

  # Instance class configurations
  instance_configs = {
    "db.t3.micro" = {
      parameters = {
        shared_buffers = "25%"
        work_mem = "4MB"
        maintenance_work_mem = "64MB"
      }
      monitoring = {
        interval = 60
        performance_insights_retention = 7
      }
      alarms = {
        cpu_utilization = 80
        free_storage_space = 1000000000  # 1GB
        database_connections = 50
      }
    }
    "db.t3.small" = {
      parameters = {
        shared_buffers = "25%"
        work_mem = "8MB"
        maintenance_work_mem = "128MB"
      }
      monitoring = {
        interval = 60
        performance_insights_retention = 7
      }
      alarms = {
        cpu_utilization = 80
        free_storage_space = 2000000000  # 2GB
        database_connections = 100
      }
    }
    "db.r5.large" = {
      parameters = {
        shared_buffers = "25%"
        work_mem = "16MB"
        maintenance_work_mem = "256MB"
      }
      monitoring = {
        interval = 30
        performance_insights_retention = 31
      }
      alarms = {
        cpu_utilization = 80
        free_storage_space = 5000000000  # 5GB
        database_connections = 200
      }
    }
  }

  # Data transformations
  transformed_data = {
    # Convert list of subnet IDs to map for easier reference
    subnet_map = { for idx, subnet in var.private_subnet_ids : "subnet-${idx}" => subnet }
    
    # Convert IAM roles list to map
    iam_roles_map = { for role in var.security_config.iam_authentication.iam_roles : role.name => role }
    
    # Convert read replicas list to map
    read_replicas_map = { for idx in range(var.read_replica_config.count) : "replica-${idx + 1}" => idx }
    
    # Merge parameter group settings with instance-specific defaults
    parameter_group_settings = merge(
      var.parameter_group_config.parameters,
      local.instance_configs[var.instance_class].parameters
    )
    
    # Merge alarm settings with instance-specific defaults
    alarm_settings = merge(
      var.alarm_config,
      {
        cpu_utilization = merge(
          var.alarm_config.cpu_utilization,
          { threshold = local.instance_configs[var.instance_class].alarms.cpu_utilization }
        )
        free_storage_space = merge(
          var.alarm_config.free_storage_space,
          { threshold = local.instance_configs[var.instance_class].alarms.free_storage_space }
        )
        database_connections = merge(
          var.alarm_config.database_connections,
          { threshold = local.instance_configs[var.instance_class].alarms.database_connections }
        )
      }
    )
  }

  # Conditional configurations
  conditional_config = {
    # Storage configuration based on instance class and auto-scaling
    storage = local.features.storage_autoscaling_enabled ? {
      allocated_storage = var.storage_config.allocated_storage
      max_allocated_storage = var.storage_config.max_allocated_storage
      storage_type = var.storage_config.storage_type
      iops = var.storage_config.iops
      storage_throughput = var.storage_config.storage_throughput
      auto_scaling = var.storage_config.auto_scaling
    } : {
      allocated_storage = var.storage_config.allocated_storage
      max_allocated_storage = null
      storage_type = var.storage_config.storage_type
      iops = var.storage_config.iops
      storage_throughput = var.storage_config.storage_throughput
      auto_scaling = null
    }

    # Monitoring configuration based on features
    monitoring = {
      interval = local.features.enhanced_monitoring_enabled ? var.monitoring_config.interval : 0
      performance_insights = local.features.performance_insights_enabled ? {
        enabled = true
        retention_period = var.monitoring_config.performance_insights.retention_period
      } : {
        enabled = false
        retention_period = null
      }
    }

    # IAM authentication configuration
    iam_auth = local.features.iam_auth_enabled ? {
      enabled = true
      iam_roles = var.security_config.iam_authentication.iam_roles
      db_user_prefix = var.security_config.iam_authentication.db_user_prefix
    } : {
      enabled = false
      iam_roles = []
      db_user_prefix = null
    }
  }
} 