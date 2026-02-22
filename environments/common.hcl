locals {
  # Common variables for all environments
  project = "terraform-project"
  region  = "us-west-2"  # Default region, can be overridden per environment
  environment = "dev"    # Default environment, will be overridden by each environment

  # Common tags for all resources
  common_tags = {
    ManagedBy   = "Terragrunt"
    Project     = local.project
    Environment = local.environment
  }
} 