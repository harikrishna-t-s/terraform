include {
  path = find_in_parent_folders()
}

locals {
  environment = "prod"
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

# Override any common variables specific to production environment
inputs = {
  environment = local.environment
  
  # Network configuration
  vpc_cidr = "10.2.0.0/16"
  private_subnet_cidrs = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  public_subnet_cidrs  = ["10.2.101.0/24", "10.2.102.0/24", "10.2.103.0/24"]
  
  # Instance configurations
  instance_type = "t3.medium"
  min_size      = 3
  max_size      = 6
  
  # Security configurations
  enable_flow_logs = true
  flow_log_retention_days = 30
  enable_network_firewall = true
  
  # Monitoring configurations
  log_retention_days = 30
  alarm_threshold = 0
  alarm_evaluation_periods = 3
  alarm_period = 300
  
  # Additional tags
  tags = merge(
    local.common_vars.locals.common_tags,
    {
      Environment = local.environment
      Project     = "security-infrastructure"
      Owner       = "Security Team"
      CostCenter  = "Security"
    }
  )
}

# Module configurations
terraform {
  source = "../../modules//vpc"
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"
  inputs = {
    environment     = local.environment
    vpc_cidr        = var.vpc_cidr
    private_subnets = var.private_subnet_cidrs
    public_subnets  = var.public_subnet_cidrs
    tags           = local.tags
  }
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security_groups"
  inputs = {
    vpc_id      = module.vpc.vpc_id
    environment = local.environment
    tags        = local.tags
  }
}

# IAM Module
module "iam" {
  source = "../../modules/iam"
  inputs = {
    environment = local.environment
    tags        = local.tags
  }
}

# S3 Module
module "s3" {
  source = "../../modules/s3"
  inputs = {
    environment = local.environment
    tags        = local.tags
  }
}

# ALB Module
module "alb" {
  source = "../../modules/alb"
  inputs = {
    environment         = local.environment
    vpc_id             = module.vpc.vpc_id
    public_subnet_ids  = module.vpc.public_subnet_ids
    alb_security_group_id = module.security_groups.alb_security_group_id
    tags               = local.tags
  }
}

# Auto Scaling Group Module
module "asg" {
  source = "../../modules/asg"
  inputs = {
    environment         = local.environment
    vpc_id             = module.vpc.vpc_id
    private_subnet_ids = module.vpc.private_subnet_ids
    alb_target_group_arn = module.alb.target_group_arn
    app_security_group_id = module.security_groups.app_security_group_id
    instance_profile_name = module.iam.app_instance_profile_name
    tags               = local.tags
  }
}

# Enhanced Security Module
module "enhanced_security" {
  source = "../../modules/enhanced_security"
  inputs = {
    environment = local.environment
    vpc_id      = module.vpc.vpc_id
    tags        = local.tags
  }
}

# Enhanced Monitoring Module
module "enhanced_monitoring" {
  source = "../../modules/enhanced_monitoring"
  inputs = {
    environment = local.environment
    tags        = local.tags
  }
}

# Zero Trust Network Module
module "zero_trust_network" {
  source = "../../modules/zero_trust_network"
  inputs = {
    environment = local.environment
    vpc_cidr    = var.vpc_cidr
    private_subnet_cidrs = var.private_subnet_cidrs
    public_subnet_cidrs  = var.public_subnet_cidrs
    enable_flow_logs = var.enable_flow_logs
    flow_log_retention_days = var.flow_log_retention_days
    enable_network_firewall = var.enable_network_firewall
    tags = local.tags
  }
}

# KMS Module
module "kms" {
  source = "../../modules/kms"
  inputs = {
    environment = local.environment
    tags        = local.tags
  }
}

# Secrets Manager Module
module "secrets_manager" {
  source = "../../modules/secrets_manager"
  inputs = {
    environment = local.environment
    kms_key_id  = module.kms.key_id
    tags        = local.tags
  }
}

# State Management Module
module "state_management" {
  source = "../../modules/state_management"
  inputs = {
    environment = local.environment
    tags        = local.tags
  }
} 