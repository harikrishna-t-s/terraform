#!/bin/bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print status
print_status() {
    echo -e "${GREEN}==>${NC} $1"
}

# Function to print error
print_error() {
    echo -e "${RED}Error:${NC} $1"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run as root"
    exit 1
fi

# Check for required tools
print_status "Checking for required tools..."

# Check for Python
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is required but not installed"
    exit 1
fi

# Check for pip
if ! command -v pip3 &> /dev/null; then
    print_error "pip3 is required but not installed"
    exit 1
fi

# Check for Terraform
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is required but not installed"
    exit 1
fi

# Check for AWS CLI
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is required but not installed"
    exit 1
fi

# Install pre-commit
print_status "Installing pre-commit..."
pip3 install pre-commit

# Install terraform-docs
print_status "Installing terraform-docs..."
if ! command -v terraform-docs &> /dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install terraform-docs
    else
        wget https://github.com/terraform-docs/terraform-docs/releases/download/v0.16.0/terraform-docs-v0.16.0-linux-amd64.tar.gz
        tar -xzf terraform-docs-v0.16.0-linux-amd64.tar.gz
        sudo mv terraform-docs /usr/local/bin/
        rm terraform-docs-v0.16.0-linux-amd64.tar.gz
    fi
fi

# Install tflint
print_status "Installing tflint..."
if ! command -v tflint &> /dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install tflint
    else
        wget https://github.com/terraform-linters/tflint/releases/download/v0.44.1/tflint_linux_amd64.zip
        unzip tflint_linux_amd64.zip
        sudo mv tflint /usr/local/bin/
        rm tflint_linux_amd64.zip
    fi
fi

# Install tfsec
print_status "Installing tfsec..."
if ! command -v tfsec &> /dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install tfsec
    else
        wget https://github.com/aquasecurity/tfsec/releases/download/v1.28.1/tfsec-linux-amd64
        sudo mv tfsec-linux-amd64 /usr/local/bin/tfsec
        sudo chmod +x /usr/local/bin/tfsec
    fi
fi

# Install checkov
print_status "Installing checkov..."
if ! command -v checkov &> /dev/null; then
    pip3 install checkov
fi

# Install pre-commit hooks
print_status "Installing pre-commit hooks..."
pre-commit install

# Create environment directories if they don't exist
print_status "Creating environment directories..."
mkdir -p environments/{dev,staging,prod}

# Create .gitignore if it doesn't exist
if [ ! -f .gitignore ]; then
    print_status "Creating .gitignore..."
    cat > .gitignore << EOL
# Local .terraform directories
**/.terraform/*

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log
crash.*.log

# Exclude all .tfvars files, which are likely to contain sensitive data
*.tfvars
*.tfvars.json

# Ignore override files as they are usually used for local development
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Ignore CLI configuration files
.terraformrc
terraform.rc

# Ignore lock files
.terraform.lock.hcl

# Ignore Mac/OSX files
.DS_Store

# Ignore IDE files
.idea/
.vscode/
*.swp
*.swo
EOL
fi

# Create versions.tf if it doesn't exist
if [ ! -f versions.tf ]; then
    print_status "Creating versions.tf..."
    cat > versions.tf << EOL
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}
EOL
fi

print_status "Setup completed successfully!"
print_status "You can now start working on your Terraform project."
print_status "Run 'make help' to see available commands." 