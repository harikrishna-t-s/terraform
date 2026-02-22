# State Management Module

This module implements secure and reliable Terraform state management using S3 for state storage, DynamoDB for state locking, and AWS Backup for automated backups.

## Features

- S3 bucket for state storage
- DynamoDB table for state locking
- KMS encryption for state files
- Automated backups with AWS Backup
- Versioning and lifecycle policies
- IAM roles and policies for backup operations

## Usage

```hcl
module "state_management" {
  source = "./modules/state_management"

  project     = var.project
  environment = var.environment
  tags        = local.common_tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project | Project name | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| state_bucket_name | Name of the S3 bucket for state storage |
| state_lock_table_name | Name of the DynamoDB table for state locking |
| kms_key_arn | ARN of the KMS key used for encryption |
| backup_vault_arn | ARN of the AWS Backup vault |

## State Management Features

### S3 Configuration
- Server-side encryption
- Versioning enabled
- Lifecycle policies
- Public access blocking
- Access logging

### DynamoDB Configuration
- Pay-per-request billing
- Point-in-time recovery
- Encryption at rest
- Auto-scaling

### KMS Configuration
- Key rotation enabled
- Key policy with least privilege
- Alias for easy reference
- CloudWatch monitoring

### AWS Backup Configuration
- Daily backups
- 30-day retention
- Cross-region backup support
- Automated backup scheduling

## Dependencies

- S3 module
- KMS module
- IAM module

## Security Considerations

- State files are encrypted at rest
- Access is restricted to authorized users
- Backup data is encrypted
- Least privilege IAM policies

## Maintenance

- Regular backup verification
- Key rotation monitoring
- Access log review
- Cost optimization

## Troubleshooting

Common issues and solutions:

1. State Lock Issues
   - Check DynamoDB table status
   - Verify IAM permissions
   - Review lock timeout settings

2. Backup Failures
   - Check backup vault status
   - Verify IAM roles
   - Review backup schedule

3. Encryption Issues
   - Verify KMS key status
   - Check key policy
   - Review encryption settings

4. Access Issues
   - Check IAM permissions
   - Verify bucket policy
   - Review VPC endpoints

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This module is licensed under the MIT License. 