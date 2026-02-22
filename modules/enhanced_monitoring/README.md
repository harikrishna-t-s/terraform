# Enhanced Monitoring Module

This module implements comprehensive monitoring and logging features for AWS infrastructure, including CloudWatch dashboards, alarms, and centralized logging.

## Features

- Centralized CloudWatch Logs
- Custom CloudWatch dashboards
- Comprehensive CloudWatch alarms
- Cost management with AWS Budgets
- Resource scheduling with SSM Maintenance Windows
- Error log monitoring and alerting

## Usage

```hcl
module "enhanced_monitoring" {
  source = "./modules/enhanced_monitoring"

  project     = var.project
  environment = var.environment
  log_retention_days = var.log_retention_days
  alarm_sns_topic_arn = var.alarm_sns_topic_arn
  monthly_budget_limit = var.monthly_budget_limit
  budget_notification_email = var.budget_notification_email
  log_destination_arn = module.s3.logs_bucket_arn
  tags        = local.common_tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project | Project name | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| log_retention_days | Number of days to retain CloudWatch logs | `number` | `30` | no |
| alarm_sns_topic_arn | ARN of the SNS topic for alarms | `string` | n/a | yes |
| monthly_budget_limit | Monthly budget limit in USD | `number` | n/a | yes |
| budget_notification_email | Email address for budget notifications | `string` | n/a | yes |
| log_destination_arn | ARN of the destination for log forwarding | `string` | n/a | yes |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloudwatch_dashboard_url | URL of the CloudWatch dashboard |
| log_group_arn | ARN of the CloudWatch log group |
| budget_id | ID of the AWS Budget |

## Monitoring Features

### CloudWatch Dashboard
- EC2 metrics (CPU, Network, Memory)
- RDS metrics (CPU, Memory, Connections)
- ALB metrics (Request Count, Response Time, Error Rates)
- Custom metrics support

### CloudWatch Alarms
- High CPU utilization
- High memory usage
- Error log monitoring
- Custom alarm support

### Cost Management
- Monthly budget tracking
- Budget notifications at 80% and 100%
- Cost allocation tags
- Resource scheduling

### Resource Scheduling
- SSM Maintenance Windows
- EventBridge rules
- Automated resource management
- Custom scheduling support

## Dependencies

- S3 module
- Enhanced Security module
- CloudWatch module

## Monitoring Considerations

- Log retention policies
- Alarm thresholds
- Budget limits
- Resource scheduling windows

## Maintenance

- Regular review of alarms
- Update dashboard metrics
- Adjust budget limits
- Review resource schedules

## Troubleshooting

Common issues and solutions:

1. CloudWatch Log Issues
   - Check log group permissions
   - Verify log retention settings
   - Review log subscription filters

2. Alarm Configuration
   - Verify alarm thresholds
   - Check SNS topic permissions
   - Review alarm actions

3. Budget Alerts
   - Verify email configuration
   - Check budget limits
   - Review notification settings

4. Resource Scheduling
   - Check maintenance window settings
   - Verify IAM permissions
   - Review schedule conflicts

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This module is licensed under the MIT License. 