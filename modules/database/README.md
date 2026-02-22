# AWS RDS Database Module

This Terraform module creates an Amazon RDS database instance with associated resources. It's designed to be secure, scalable, and follows AWS best practices.

## Features

- Multi-AZ RDS instance deployment
- Automated backups with configurable retention
- Enhanced monitoring and Performance Insights
- CloudWatch alarms for key metrics
- KMS encryption for data at rest
- Security group with least privilege access
- Comprehensive backup and maintenance windows
- Deletion protection
- Customizable instance type and storage

## Usage

```hcl
module "database" {
  source = "./modules/database"

  environment = "prod"
  vpc_id      = "vpc-12345678"
  database_subnet_ids = ["subnet-12345678", "subnet-87654321"]
  app_security_group_id = "sg-12345678"

  # Database configuration
  database_name     = "myapp"
  database_username = "admin"
  database_password = "secure-password"

  # Engine configuration
  engine         = "postgres"
  engine_version = "14.7"
  instance_class = "db.t3.micro"

  # Storage configuration
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type         = "gp2"

  # Monitoring configuration
  monitoring_interval = 60
  sns_topic_arn      = "arn:aws:sns:region:account:topic-name"

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
| vpc_id | The VPC ID where the RDS instance will be created | `string` | n/a | yes |
| database_subnet_ids | List of VPC subnet IDs for the DB subnet group | `list(string)` | n/a | yes |
| app_security_group_id | Security group ID of the application layer | `string` | n/a | yes |
| database_name | The name of the database to create | `string` | n/a | yes |
| database_username | Username for the master DB user | `string` | n/a | yes |
| database_password | Password for the master DB user | `string` | n/a | yes |
| engine | The database engine to use | `string` | `"postgres"` | no |
| engine_version | The engine version to use | `string` | `"14.7"` | no |
| instance_class | The instance type of the RDS instance | `string` | `"db.t3.micro"` | no |
| allocated_storage | The amount of allocated storage in GB | `number` | `20` | no |
| max_allocated_storage | The upper limit for automatic storage scaling | `number` | `100` | no |
| storage_type | The storage type for the DB instance | `string` | `"gp2"` | no |
| database_port | The port on which the DB accepts connections | `number` | `5432` | no |
| multi_az | Specifies if the RDS instance is multi-AZ | `bool` | `true` | no |
| backup_retention_period | The number of days to retain backups | `number` | `7` | no |
| backup_window | The daily time range for backups | `string` | `"03:00-04:00"` | no |
| maintenance_window | The window to perform maintenance | `string` | `"Mon:04:00-Mon:05:00"` | no |
| monitoring_interval | The interval for Enhanced Monitoring | `number` | `60` | no |
| performance_insights_retention_period | Retention period for Performance Insights | `number` | `7` | no |
| cpu_utilization_threshold | Threshold for CPU utilization alarm | `number` | `80` | no |
| free_storage_space_threshold | Threshold for free storage space alarm | `number` | `1000000000` | no |
| database_connections_threshold | Threshold for database connections alarm | `number` | `100` | no |
| deletion_protection | If the DB instance should have deletion protection | `bool` | `true` | no |
| sns_topic_arn | The ARN of the SNS topic for CloudWatch alarms | `string` | n/a | yes |
| tags | Additional tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| db_instance_id | The RDS instance ID |
| db_instance_address | The address of the RDS instance |
| db_instance_endpoint | The connection endpoint of the RDS instance |
| db_instance_name | The database name |
| db_instance_username | The master username for the database |
| db_instance_port | The database port |
| db_security_group_id | The security group ID of the RDS instance |
| db_subnet_group_id | The db subnet group name |
| db_monitoring_role_arn | The ARN of the IAM role for RDS monitoring |
| cloudwatch_alarm_ids | Map of CloudWatch alarm IDs |
| kms_key_id | The ID of the KMS key used for RDS encryption |
| kms_key_arn | The ARN of the KMS key used for RDS encryption |

## Security

- KMS encryption for data at rest
- Security group with least privilege access
- Deletion protection enabled by default
- Automated backups with encryption
- Enhanced monitoring and audit logging
- Performance Insights for query analysis

## Monitoring

The module creates the following CloudWatch alarms:
- CPU utilization alarm
- Free storage space alarm
- Database connections alarm

## Backup and Recovery

- Automated daily backups
- Configurable backup retention period
- Point-in-time recovery
- Multi-AZ deployment for high availability
- Maintenance windows for updates

## Cost Considerations

- RDS instance pricing based on:
  - Instance type
  - Storage type and size
  - Multi-AZ deployment
- Backup storage costs
- Performance Insights costs
- CloudWatch monitoring costs

## Troubleshooting

### Common Issues

1. **Connection Issues**
   - Verify security group rules
   - Check VPC and subnet configuration
   - Ensure proper network ACLs

2. **Performance Issues**
   - Monitor CPU and memory utilization
   - Check storage space
   - Review Performance Insights

3. **Backup Issues**
   - Verify backup window configuration
   - Check storage space for backups
   - Ensure proper IAM permissions

## License

MIT License 