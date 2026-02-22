locals {
  # Naming prefixes
  name_prefix = "${var.naming_prefix}-${var.environment}"
  
  # Common tags for all resources
  common_tags = {
      Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    CostCenter  = var.cost_center
    Owner       = var.owner
    Department  = var.department
  }

  # Subnet tier tags
  subnet_tier_tags = {
    public   = "Public"
    private  = "Private"
    database = "Database"
  }

  # Centralized CIDR block management
  cidr_blocks = {
    dev = {
      vpc_cidr             = var.vpc_cidr
      public_subnet_cidrs  = var.public_subnet_cidrs
      private_subnet_cidrs = var.private_subnet_cidrs
      database_subnet_cidrs = var.database_subnet_cidrs
    }
    prod = {
    vpc_cidr             = var.vpc_cidr
      public_subnet_cidrs  = var.public_subnet_cidrs
      private_subnet_cidrs = var.private_subnet_cidrs
      database_subnet_cidrs = var.database_subnet_cidrs
    }
  }
} 