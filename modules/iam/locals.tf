locals {
  # Naming prefixes
  name_prefix = "${var.naming_prefix}-${var.environment}"

  # Common tags for all resources
  common_tags = merge(
    var.common_tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      CostCenter  = var.cost_center
      Owner       = var.owner
      Department  = var.department
    }
  )

  # Role configuration
  role_config = {
    path = var.iam_path
  }

  # Policy configuration
  policy_config = {
    path = var.iam_path
  }

  # EC2 configuration
  ec2_config = {
    enable_ssm        = var.enable_ec2_ssm
    enable_cloudwatch = var.enable_ec2_cloudwatch
  }

  # Lambda configuration
  lambda_config = {
    enable_basic = var.enable_lambda_basic
  }

  # ECS configuration
  ecs_config = {
    enable_task_execution = var.enable_ecs_task_execution
  }

  # RDS configuration
  rds_config = {
    enable_monitoring = var.enable_rds_monitoring
  }
} 