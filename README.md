# Terraform AWS Infrastructure Project with Terragrunt

This project implements a secure, scalable, and maintainable AWS infrastructure using Terraform and Terragrunt, following industry best practices for security, compliance, and operational excellence.

## Features

### Infrastructure as Code
- Terraform for infrastructure provisioning
- Terragrunt for DRY configuration management
- Modular architecture
- Environment-specific configurations
- Remote state management
- State locking with DynamoDB

### Security & Compliance
- AWS GuardDuty for threat detection
- AWS Config for compliance monitoring
- Security Hub for security standards
- KMS encryption for data at rest
- VPC endpoints for secure access
- Least privilege IAM roles
- Secrets management with rotation
- Automated security scanning
- Compliance monitoring and reporting

### Infrastructure Components
- VPC with public and private subnets
- S3 buckets with encryption
- RDS instances with encryption
- CloudWatch monitoring and alerts
- SNS topics for notifications
- IAM roles and policies
- Security groups and NACLs
- Route tables and internet gateways

### Operational Features
- Remote state management
- State locking with DynamoDB
- Automated backups
- Monitoring and alerting
- Logging and audit trails
- Resource tagging
- Cost management

## Prerequisites

- Terraform >= 1.0.0
- Terragrunt >= 0.45.0
- AWS CLI configured
- AWS account with appropriate permissions
- S3 bucket for remote state
- DynamoDB table for state locking

## Project Structure

```
.
├── modules/                    # Reusable Terraform modules
│   ├── security/              # Security and compliance
│   ├── networking/            # VPC and networking
│   ├── storage/              # S3 and RDS
│   ├── monitoring/           # CloudWatch and alerts
│   ├── iam/                 # IAM roles and policies
│   └── secrets/             # Secrets management
├── environments/              # Environment-specific configurations
│   ├── common.hcl            # Common configuration
│   ├── dev/
│   │   └── terragrunt.hcl    # Dev environment config
│   ├── staging/
│   │   └── terragrunt.hcl    # Staging environment config
│   └── prod/
│       └── terragrunt.hcl    # Production environment config
├── terragrunt.hcl            # Root configuration
├── scripts/                   # Utility scripts
│   ├── security-scan.sh
│   └── compliance-check.sh
└── docs/                     # Documentation
    ├── architecture.md
    ├── security.md
    ├── compliance.md
    └── runbook.md
```

## Getting Started

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

4. Deploy to an environment:
   ```bash
   # For dev environment
   cd environments/dev
   terragrunt init
   terragrunt plan
   terragrunt apply
   
   # For staging environment
   cd environments/staging
   terragrunt init
   terragrunt plan
   terragrunt apply
   
   # For production environment
   cd environments/prod
   terragrunt init
   terragrunt plan
   terragrunt apply
   ```

5. Run-all commands (deploy all modules in an environment):
   ```bash
   cd environments/dev
   terragrunt run-all init
   terragrunt run-all plan
   terragrunt run-all apply
   ```

## Terragrunt Configuration

### Root Configuration (terragrunt.hcl)
- Common provider settings
- Remote state configuration
- Version constraints
- Common inputs

### Environment Configurations
Each environment has its own `terragrunt.hcl` with:
- Environment-specific variables
- Network configurations
- Instance configurations
- Security settings
- Monitoring parameters
- Resource tags

### Common Configuration (common.hcl)
- Shared variables
- Common tags
- Default settings

## Security Scanning

Run security scans:
```bash
./scripts/security-scan.sh
```

## Compliance Checks

Run compliance checks:
```bash
./scripts/compliance-check.sh
```

## Monitoring

- CloudWatch Dashboards: [Dashboard URLs]
- Alert Thresholds:
  - CPU Utilization: > 80%
  - Memory Usage: > 85%
  - Disk Space: > 90%
  - Error Rate: > 1%

## Backup and Recovery

- Automated daily backups
- Retention period: 7 days
- Manual backup procedure in runbook
- State file recovery process

## Maintenance

### Regular Tasks
- Security updates
- Compliance checks
- Backup verification
- Cost optimization
- Performance monitoring

### Key Rotation
- KMS keys
- IAM access keys
- Database credentials
- Application secrets

## Troubleshooting

Common issues and solutions are documented in the runbook:
- State lock issues
- Provider authentication
- Resource creation failures
- Security incidents

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License.

## Support

For support, please contact:
- Primary On-Call: [Contact Information]
- Secondary On-Call: [Contact Information]
- Infrastructure Team: [Contact Information]

## Additional Documentation

- [Architecture Documentation](docs/architecture.md)
- [Runbook](docs/runbook.md)
- [Security Guidelines](docs/security.md)
- [Compliance Requirements](docs/compliance.md) 