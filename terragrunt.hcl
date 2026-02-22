locals {
  # Load common variables from environment-specific tfvars
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment = local.common_vars.locals.environment
  project     = local.common_vars.locals.project
  region      = local.common_vars.locals.region

  # Load module configuration
  module_config = read_terragrunt_config(find_in_parent_folders("modules.hcl"))
  module_paths = local.module_config.locals.module_paths
  module_dependencies = local.module_config.locals.module_dependencies
}

# Generate AWS provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"
  
  default_tags {
    tags = {
      Environment = "${local.environment}"
      Project     = "${local.project}"
      ManagedBy   = "Terragrunt"
    }
  }
}
EOF
}

# Generate version constraints
generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF
}

# Configure remote state
remote_state {
  backend = "s3"
  config = {
    bucket         = "${local.project}-${local.environment}-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "${local.project}-${local.environment}-terraform-locks"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Generate backend configuration
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket         = "${local.project}-${local.environment}-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "${local.region}"
    encrypt        = true
    dynamodb_table = "${local.project}-${local.environment}-terraform-locks"
  }
}
EOF
}

# Configure inputs that will be passed to all child modules
inputs = {
  environment = local.environment
  project     = local.project
  region      = local.region
}

# Configure module dependencies
dependency "vpc" {
  config_path = "${local.module_paths["vpc"]}"
}

dependency "security_groups" {
  config_path = "${local.module_paths["security_groups"]}"
  dependencies = ["vpc"]
}

dependency "iam" {
  config_path = "${local.module_paths["iam"]}"
}

dependency "s3" {
  config_path = "${local.module_paths["s3"]}"
}

dependency "alb" {
  config_path = "${local.module_paths["alb"]}"
  dependencies = ["vpc", "security_groups"]
}

dependency "asg" {
  config_path = "${local.module_paths["asg"]}"
  dependencies = ["vpc", "alb", "security_groups", "iam"]
}

dependency "enhanced_security" {
  config_path = "${local.module_paths["enhanced_security"]}"
  dependencies = ["vpc"]
}

dependency "enhanced_monitoring" {
  config_path = "${local.module_paths["enhanced_monitoring"]}"
}

dependency "zero_trust_network" {
  config_path = "${local.module_paths["zero_trust_network"]}"
  dependencies = ["vpc"]
}

dependency "kms" {
  config_path = "${local.module_paths["kms"]}"
}

dependency "secrets_manager" {
  config_path = "${local.module_paths["secrets_manager"]}"
  dependencies = ["kms"]
}

dependency "state_management" {
  config_path = "${local.module_paths["state_management"]}"
} 