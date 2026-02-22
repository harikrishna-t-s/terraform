# Infrastructure Runbook

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Deployment Procedures](#deployment-procedures)
4. [Maintenance Tasks](#maintenance-tasks)
5. [Troubleshooting](#troubleshooting)
6. [Emergency Procedures](#emergency-procedures)

## Prerequisites

### Required Tools
- Terraform >= 1.0.0
- Terragrunt >= 0.45.0
- AWS CLI
- Git

### Required Access
- AWS account with appropriate permissions
- S3 bucket for remote state
- DynamoDB table for state locking

## Environment Setup

### Initial Setup
1. Clone the repository:
   ```bash
   git clone [repository-url]
   cd [repository-name]
   ```

2. Install Terragrunt:
   ```bash
   # For macOS
   brew install terragrunt
   
   # For Linux
   wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.45.0/terragrunt_linux_amd64
   sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
   sudo chmod +x /usr/local/bin/terragrunt
   ```

3. Configure AWS credentials:
   ```bash
   aws configure
   ```

### Environment Configuration
1. Review and update `environments/common.hcl`:
   - Project name
   - Default region
   - Common tags

2. Review environment-specific configurations:
   - `environments/dev/terragrunt.hcl`
   - `environments/staging/terragrunt.hcl`
   - `environments/prod/terragrunt.hcl`

## Deployment Procedures

### Standard Deployment
1. Navigate to target environment:
   ```bash
   cd environments/[dev|staging|prod]
   ```

2. Initialize Terragrunt:
   ```bash
   terragrunt init
   ```

3. Plan changes:
   ```bash
   terragrunt plan
   ```

4. Apply changes:
   ```bash
   terragrunt apply
   ```

### Multi-module Deployment
1. Navigate to target environment:
   ```bash
   cd environments/[dev|staging|prod]
   ```

2. Initialize all modules:
   ```bash
   terragrunt run-all init
   ```

3. Plan all changes:
   ```bash
   terragrunt run-all plan
   ```

4. Apply all changes:
   ```bash
   terragrunt run-all apply
   ```

## Maintenance Tasks

### Regular Maintenance
1. Update Terragrunt:
   ```bash
   # Check current version
   terragrunt --version
   
   # Update to latest version
   brew upgrade terragrunt  # macOS
   # or
   wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.45.0/terragrunt_linux_amd64  # Linux
   ```

2. Clean Terragrunt cache:
   ```bash
   terragrunt clean
   ```

3. Validate configurations:
   ```bash
   terragrunt validate-inputs
   ```

### State Management
1. List state files:
   ```bash
   aws s3 ls s3://[bucket-name]/[environment]/
   ```

2. Backup state:
   ```bash
   aws s3 cp s3://[bucket-name]/[environment]/terraform.tfstate terraform.tfstate.backup
   ```

3. Restore state:
   ```bash
   aws s3 cp terraform.tfstate.backup s3://[bucket-name]/[environment]/terraform.tfstate
   ```

## Troubleshooting

### Common Issues

#### State Lock Issues
1. Check DynamoDB table:
   ```bash
   aws dynamodb scan --table-name [table-name]
   ```

2. Force unlock:
   ```bash
   terragrunt force-unlock [lock-id]
   ```

#### Provider Authentication
1. Verify AWS credentials:
   ```bash
   aws sts get-caller-identity
   ```

2. Check AWS configuration:
   ```bash
   cat ~/.aws/credentials
   cat ~/.aws/config
   ```

#### Module Dependencies
1. Check dependency graph:
   ```bash
   terragrunt graph-dependencies
   ```

2. Validate module references:
   ```bash
   terragrunt validate-inputs
   ```

### Terragrunt-specific Issues

#### Cache Issues
1. Clear Terragrunt cache:
   ```bash
   terragrunt clean
   ```

2. Remove .terragrunt-cache:
   ```bash
   rm -rf .terragrunt-cache
   ```

#### Configuration Issues
1. Validate configuration:
   ```bash
   terragrunt validate-inputs
   ```

2. Check configuration inheritance:
   ```bash
   terragrunt graph-dependencies
   ```

## Emergency Procedures

### State Recovery
1. Identify the issue:
   ```bash
   aws s3 ls s3://[bucket-name]/[environment]/
   ```

2. Restore from backup:
   ```bash
   aws s3 cp s3://[bucket-name]/[environment]/backup/terraform.tfstate s3://[bucket-name]/[environment]/terraform.tfstate
   ```

3. Reinitialize:
   ```bash
   terragrunt init
   ```

### Resource Recovery
1. Identify affected resources:
   ```bash
   terragrunt state list
   ```

2. Import missing resources:
   ```bash
   terragrunt import [resource] [resource-id]
   ```

3. Verify state:
   ```bash
   terragrunt state show [resource]
   ```

### Emergency Rollback
1. Identify last known good state:
   ```bash
   aws s3 ls s3://[bucket-name]/[environment]/backup/
   ```

2. Restore state:
   ```bash
   aws s3 cp s3://[bucket-name]/[environment]/backup/[timestamp]/terraform.tfstate s3://[bucket-name]/[environment]/terraform.tfstate
   ```

3. Apply rollback:
   ```bash
   terragrunt apply
   ```

## Contact Information

### On-Call Support
- Primary: [Contact Information]
- Secondary: [Contact Information]

### Escalation Path
1. Infrastructure Team
2. DevOps Team
3. Security Team
4. CTO

## Change Management

### Change Request Process
1. Create change request
2. Review and approve
3. Schedule change window
4. Execute change
5. Verify change
6. Document change

### Emergency Change Process
1. Notify stakeholders
2. Create emergency change request
3. Execute change
4. Document change
5. Post-mortem review

## Appendix

### Useful Commands
```bash
# List resources
terraform state list

# Show resource details
terraform state show [resource]

# Import resources
terraform import [resource] [id]

# Output values
terraform output
```

### Important URLs
- AWS Console: [URL]
- CloudWatch: [URL]
- Terraform Cloud: [URL]
- Documentation: [URL]

### Reference Documentation
- [AWS Documentation]
- [Terraform Documentation]
- [Security Guidelines]
- [Compliance Requirements] 