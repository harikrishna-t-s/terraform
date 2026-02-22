locals {
  # Resource naming
  name_prefix = "s3-${var.environment}"

  # Common tags
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "s3"
    }
  )

  # Bucket naming
  bucket_names = {
    terraform_state = var.terraform_state_bucket_name != "" ? var.terraform_state_bucket_name : "${local.name_prefix}-terraform-state"
    alb_logs       = var.alb_logs_bucket_name != "" ? var.alb_logs_bucket_name : "${local.name_prefix}-alb-logs"
    cloudtrail_logs = var.cloudtrail_logs_bucket_name != "" ? var.cloudtrail_logs_bucket_name : "${local.name_prefix}-cloudtrail-logs"
    config_logs    = var.config_logs_bucket_name != "" ? var.config_logs_bucket_name : "${local.name_prefix}-config-logs"
    app_logs       = var.app_logs_bucket_name != "" ? var.app_logs_bucket_name : "${local.name_prefix}-app-logs"
    db_backups     = var.db_backups_bucket_name != "" ? var.db_backups_bucket_name : "${local.name_prefix}-db-backups"
  }

  # Common bucket configurations
  common_bucket_config = {
    versioning_enabled = var.enable_versioning
    lifecycle_enabled  = var.enable_lifecycle_rules
    public_access_blocked = var.block_public_access
  }
} 