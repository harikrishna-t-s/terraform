# Enhanced Security Module

This module implements comprehensive security features for AWS infrastructure, including WAF, Shield, GuardDuty, and Security Hub integration.

## Features

- AWS WAF with managed rule sets
- AWS Shield Advanced for DDoS protection
- GuardDuty with enhanced data sources
- Security Hub with CIS and AWS Foundational standards
- CloudWatch alarms for security events

## Usage

```hcl
module "enhanced_security" {
  source = "./modules/enhanced_security"

  project     = var.project
  environment = var.environment
  alb_arn     = module.alb.alb_arn
  alarm_sns_topic_arn = var.alarm_sns_topic_arn
  tags        = local.common_tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project | Project name | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| alb_arn | ARN of the Application Load Balancer | `string` | n/a | yes |
| alarm_sns_topic_arn | ARN of the SNS topic for alarms | `string` | n/a | yes |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| waf_web_acl_arn | ARN of the WAF Web ACL |
| guardduty_detector_id | ID of the GuardDuty detector |
| security_hub_account_id | ID of the Security Hub account |

## Security Features

### WAF Configuration
- AWS Managed Rules
- Custom rules support
- Rate limiting
- IP blocking
- SQL injection protection
- XSS protection

### GuardDuty
- S3 protection
- Malware protection
- Kubernetes audit logs
- EBS volume scanning

### Security Hub
- CIS AWS Foundations Benchmark
- AWS Foundational Security Best Practices
- Custom security standards
- Automated compliance checks

### CloudWatch Alarms
- GuardDuty findings
- WAF blocked requests
- Security Hub findings

## Dependencies

- ALB module
- S3 module
- CloudWatch module

## Security Considerations

- WAF rules are regularly updated
- GuardDuty findings are monitored
- Security Hub standards are enforced
- Alarms are configured for critical events

## Maintenance

- Regular review of WAF rules
- Monitor GuardDuty findings
- Update security standards
- Review and update alarms

## Troubleshooting

Common issues and solutions:

1. WAF Rule Conflicts
   - Check rule priorities
   - Review rule conditions
   - Verify rule actions

2. GuardDuty False Positives
   - Review finding details
   - Adjust detection thresholds
   - Update suppression rules

3. Security Hub Standards
   - Check standard status
   - Review failed controls
   - Update remediation actions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This module is licensed under the MIT License. 