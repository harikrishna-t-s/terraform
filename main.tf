terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "cybersecurity-platform"
      ManagedBy   = "terraform"
    }
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  environment     = var.environment
  vpc_cidr        = var.vpc_cidr
  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = false
  enable_vpn_gateway = false

  tags = local.tags
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security_groups"

  vpc_id     = module.vpc.vpc_id
  environment = var.environment
  tags       = local.tags
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  environment = var.environment
  app_logs_bucket_arn = module.s3.app_logs_bucket_arn
  db_backups_bucket_arn = module.s3.db_backups_bucket_arn
  kms_key_arn = module.s3.kms_key_arn
  tags       = local.tags
}

# Database Module
module "database" {
  source = "./modules/database"

  environment        = var.environment
  vpc_id            = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  db_security_group_id = module.security_groups.db_security_group_id
  tags              = local.tags
}

# Application Load Balancer Module
module "alb" {
  source = "./modules/alb"

  environment         = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id
  alb_logs_bucket_id = module.s3.alb_logs_bucket_id
  tags               = local.tags
}

# Auto Scaling Group Module
module "asg" {
  source = "./modules/asg"

  environment         = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  alb_target_group_arn = module.alb.target_group_arn
  app_security_group_id = module.security_groups.app_security_group_id
  instance_profile_name = module.iam.app_instance_profile_name
  tags               = local.tags
}

# S3 Module
module "s3" {
  source = "./modules/s3"

  environment = var.environment
  tags       = local.tags
}

# CloudWatch Module
module "cloudwatch" {
  source = "./modules/cloudwatch"

  environment = var.environment
  tags       = local.tags
}

# CloudTrail Module
module "cloudtrail" {
  source = "./modules/cloudtrail"

  environment = var.environment
  s3_bucket_id = module.s3.cloudtrail_bucket_id
  tags        = local.tags
}

# AWS Config Module
module "aws_config" {
  source = "./modules/aws_config"

  environment = var.environment
  tags       = local.tags
}

# Security Module
module "security" {
  source = "./modules/security"

  project              = var.project
  environment          = var.environment
  config_bucket_name   = module.s3.config_bucket_name
  config_sns_topic_arn = module.sns.config_topic_arn
  alarm_sns_topic_arn  = module.sns.alarm_topic_arn
  tags                 = local.common_tags
}

# SNS Module
module "sns" {
  source = "./modules/sns"
  # ... existing configuration ...
}

locals {
  name_prefix = "security-${var.environment}"
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = "security-infrastructure"
      ManagedBy   = "terraform"
    }
  )
}

module "zero_trust_network" {
  source = "./modules/zero_trust_network"

  environment = var.environment
  vpc_cidr    = var.zero_trust_network.vpc_cidr
  
  private_subnet_cidrs = var.zero_trust_network.private_subnet_cidrs
  public_subnet_cidrs  = var.zero_trust_network.public_subnet_cidrs
  
  enable_flow_logs = var.zero_trust_network.enable_flow_logs
  flow_log_retention_days = var.zero_trust_network.flow_log_retention_days
  
  enable_network_firewall = var.zero_trust_network.enable_network_firewall
  firewall_policy_arn     = var.zero_trust_network.firewall_policy_arn

  config_logs_bucket_id = module.s3.config_logs_bucket_id

  tags = local.common_tags
}

module "security_automation" {
  source = "./modules/security_automation"

  environment = var.environment
  vpc_id      = var.vpc_id
  private_subnet_ids = module.zero_trust_network.private_subnet_ids

  lambda_timeout = var.security_automation.lambda_timeout
  lambda_memory_size = var.security_automation.lambda_memory_size
  log_retention_days = var.security_automation.log_retention_days
  alarm_threshold = var.security_automation.alarm_threshold
  alarm_evaluation_periods = var.security_automation.alarm_evaluation_periods
  alarm_period = var.security_automation.alarm_period

  tags = local.common_tags
}

module "threat_hunting" {
  source = "./modules/threat_hunting"

  environment = var.environment
  vpc_id      = var.vpc_id
  private_subnet_ids = module.zero_trust_network.private_subnet_ids

  opensearch_instance_type = var.threat_hunting.opensearch_instance_type
  opensearch_instance_count = var.threat_hunting.opensearch_instance_count
  opensearch_master_username = var.threat_hunting.opensearch_master_username
  opensearch_master_password = var.threat_hunting.opensearch_master_password
  opensearch_ebs_volume_size = var.threat_hunting.opensearch_ebs_volume_size
  opensearch_master_instance_type = var.threat_hunting.opensearch_master_instance_type

  tags = local.common_tags
}

# Enhanced Security Module
module "enhanced_security" {
  source = "./modules/enhanced_security"

  project     = var.project
  environment = var.environment
  alb_arn     = module.alb.alb_arn
  alarm_sns_topic_arn = var.alarm_sns_topic_arn
  tags        = local.common_tags

  depends_on = [
    module.alb,
    module.s3
  ]
}

# Enhanced Monitoring Module
module "enhanced_monitoring" {
  source = "./modules/enhanced_monitoring"

  project     = var.project
  environment = var.environment
  log_retention_days = var.log_retention_days
  alarm_sns_topic_arn = var.alarm_sns_topic_arn
  monthly_budget_limit = var.monthly_budget_limit
  budget_notification_email = var.budget_notification_email
  log_destination_arn = module.s3.logs_bucket_arn
  tags        = local.common_tags

  depends_on = [
    module.s3,
    module.enhanced_security
  ]
}

# State Management Module
module "state_management" {
  source = "./modules/state_management"

  project     = var.project
  environment = var.environment
  tags        = local.common_tags

  depends_on = [
    module.s3
  ]
} 