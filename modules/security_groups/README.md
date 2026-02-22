# AWS Security Groups Module

This Terraform module creates security groups for various AWS services in a VPC. It's designed to follow security best practices and provide granular control over network access.

## Features

- Security groups for ALB, application servers, databases, and more
- Configurable ingress and egress rules
- Support for multiple database types (PostgreSQL, MySQL)
- Bastion host security group
- Redis and Elasticsearch security groups
- VPC endpoints security group
- Comprehensive tagging strategy

## Usage

```hcl
module "security_groups" {
  source = "./modules/security_groups"

  environment = "prod"
  vpc_id      = "vpc-12345678"
  vpc_cidr_block = "10.0.0.0/16"

  # ALB configuration
  alb_ingress_cidr_blocks = ["0.0.0.0/0"]
  enable_alb_http        = true
  enable_alb_https       = true

  # Bastion configuration
  bastion_ingress_cidr_blocks = ["203.0.113.0/24"]

  # Database configuration
  enable_db_postgres = true
  enable_db_mysql    = false

  # Additional services
  enable_redis        = true
  enable_elasticsearch = true
  enable_vpc_endpoints = true

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
| vpc_id | ID of the VPC where security groups will be created | `string` | n/a | yes |
| vpc_cidr_block | CIDR block of the VPC | `string` | n/a | yes |
| environment | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| alb_ingress_cidr_blocks | List of CIDR blocks allowed to access the ALB | `list(string)` | `["0.0.0.0/0"]` | no |
| bastion_ingress_cidr_blocks | List of CIDR blocks allowed to access the bastion host | `list(string)` | `[]` | no |
| enable_alb_http | Whether to enable HTTP access to ALB | `bool` | `true` | no |
| enable_alb_https | Whether to enable HTTPS access to ALB | `bool` | `true` | no |
| enable_app_ssh | Whether to enable SSH access to application servers | `bool` | `true` | no |
| enable_db_postgres | Whether to enable PostgreSQL access to database | `bool` | `true` | no |
| enable_db_mysql | Whether to enable MySQL access to database | `bool` | `false` | no |
| enable_redis | Whether to enable Redis security group | `bool` | `false` | no |
| enable_elasticsearch | Whether to enable Elasticsearch security group | `bool` | `false` | no |
| enable_vpc_endpoints | Whether to enable VPC endpoints security group | `bool` | `false` | no |
| name_prefix | Prefix to use for resource names | `string` | `""` | no |
| tags | Additional tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_security_group_id | ID of the ALB security group |
| alb_security_group_name | Name of the ALB security group |
| app_security_group_id | ID of the application security group |
| app_security_group_name | Name of the application security group |
| db_security_group_id | ID of the database security group |
| db_security_group_name | Name of the database security group |
| bastion_security_group_id | ID of the bastion security group |
| bastion_security_group_name | Name of the bastion security group |
| redis_security_group_id | ID of the Redis security group |
| redis_security_group_name | Name of the Redis security group |
| elasticsearch_security_group_id | ID of the Elasticsearch security group |
| elasticsearch_security_group_name | Name of the Elasticsearch security group |
| vpc_endpoints_security_group_id | ID of the VPC endpoints security group |
| vpc_endpoints_security_group_name | Name of the VPC endpoints security group |

## Security

- Principle of least privilege
- Granular control over network access
- Security group rules based on service requirements
- Bastion host for secure SSH access
- VPC endpoints for private AWS service access

## Best Practices

1. **Network Security**
   - Use security groups for instance-level security
   - Implement least privilege access
   - Regular security group review

2. **Access Control**
   - Restrict access to bastion host
   - Use security groups for service-to-service communication
   - Implement proper database access controls

3. **Monitoring and Logging**
   - Enable VPC Flow Logs
   - Monitor security group changes
   - Regular security audits

## Cost Considerations

- Security groups are free
- No direct costs associated with security groups
- Indirect costs through service usage

## Troubleshooting

### Common Issues

1. **Connectivity Issues**
   - Verify security group rules
   - Check VPC configuration
   - Review network ACLs

2. **Access Issues**
   - Verify CIDR blocks
   - Check security group associations
   - Review instance metadata

3. **Service Issues**
   - Verify service ports
   - Check service dependencies
   - Review service configurations

## License

MIT License 