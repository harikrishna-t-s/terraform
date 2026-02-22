# AWS IAM Module

This Terraform module creates IAM roles, policies, and instance profiles for various AWS services. It's designed to follow the principle of least privilege and AWS best practices.

## Features

- IAM roles for EC2, Lambda, ECS, and RDS
- Instance profiles for EC2 instances
- Custom policies for common use cases
- Systems Manager (SSM) integration
- CloudWatch logging integration
- KMS key policy management
- Comprehensive tagging strategy

## Usage

```hcl
module "iam" {
  source = "./modules/iam"

  environment = "prod"
  kms_key_id  = "arn:aws:kms:region:account:key/key-id"

  # EC2 configuration
  enable_ec2_ssm        = true
  enable_ec2_cloudwatch = true

  # Lambda configuration
  enable_lambda_basic = true

  # ECS configuration
  enable_ecs_task_execution = true

  # RDS configuration
  enable_rds_monitoring = true

  # Additional policies
  additional_ec2_policies = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  tags = {
    Project     = "MyProject"
    Environment = "production"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| kms_key_id | ID of the KMS key to attach policies to | `string` | n/a | yes |
| enable_ec2_ssm | Whether to enable Systems Manager access for EC2 instances | `bool` | `true` | no |
| enable_ec2_cloudwatch | Whether to enable CloudWatch access for EC2 instances | `bool` | `true` | no |
| enable_lambda_basic | Whether to enable basic Lambda execution policy | `bool` | `true` | no |
| enable_ecs_task_execution | Whether to enable ECS task execution policy | `bool` | `true` | no |
| enable_rds_monitoring | Whether to enable RDS monitoring role | `bool` | `true` | no |
| additional_ec2_policies | Additional IAM policy ARNs to attach to EC2 role | `list(string)` | `[]` | no |
| additional_lambda_policies | Additional IAM policy ARNs to attach to Lambda role | `list(string)` | `[]` | no |
| additional_ecs_policies | Additional IAM policy ARNs to attach to ECS roles | `list(string)` | `[]` | no |
| iam_path | Path to create IAM resources under | `string` | `"/"` | no |
| name_prefix | Prefix to use for resource names | `string` | `""` | no |
| tags | Additional tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| ec2_role_arn | ARN of the IAM role for EC2 instances |
| ec2_role_name | Name of the IAM role for EC2 instances |
| ec2_instance_profile_arn | ARN of the IAM instance profile for EC2 instances |
| ec2_instance_profile_name | Name of the IAM instance profile for EC2 instances |
| lambda_role_arn | ARN of the IAM role for Lambda functions |
| lambda_role_name | Name of the IAM role for Lambda functions |
| ecs_task_role_arn | ARN of the IAM role for ECS tasks |
| ecs_task_role_name | Name of the IAM role for ECS tasks |
| ecs_task_execution_role_arn | ARN of the IAM role for ECS task execution |
| ecs_task_execution_role_name | Name of the IAM role for ECS task execution |
| rds_monitoring_role_arn | ARN of the IAM role for RDS monitoring |
| rds_monitoring_role_name | Name of the IAM role for RDS monitoring |
| ec2_ssm_policy_arn | ARN of the IAM policy for EC2 SSM access |
| ec2_cloudwatch_policy_arn | ARN of the IAM policy for EC2 CloudWatch access |
| lambda_basic_policy_arn | ARN of the IAM policy for basic Lambda execution |
| ecs_task_execution_policy_arn | ARN of the IAM policy for ECS task execution |

## Security

- Principle of least privilege
- Custom policies for specific use cases
- KMS key policy management
- Secure role assumption policies
- Comprehensive audit logging

## Best Practices

1. **Role Management**
   - Use separate roles for different services
   - Implement least privilege access
   - Regular policy review and updates

2. **Policy Management**
   - Use custom policies for specific needs
   - Avoid wildcard permissions
   - Regular policy audit

3. **Instance Profiles**
   - Use instance profiles for EC2
   - Avoid hardcoding credentials
   - Regular credential rotation

## Cost Considerations

- IAM is a free service
- No direct costs associated with IAM resources
- Indirect costs through service usage

## Troubleshooting

### Common Issues

1. **Permission Issues**
   - Verify role trust relationships
   - Check policy permissions
   - Review service principal

2. **Instance Profile Issues**
   - Verify instance profile attachment
   - Check role permissions
   - Review instance metadata service

3. **Policy Issues**
   - Verify policy syntax
   - Check resource ARNs
   - Review action permissions

## License

MIT License 