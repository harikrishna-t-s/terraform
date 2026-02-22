# AWS Application Load Balancer (ALB) Module

This Terraform module creates a complete AWS Application Load Balancer (ALB) setup with integrated WAF protection, dynamic listener rules, and comprehensive monitoring. The module is designed to be modular, reusable, and follows AWS best practices for security and performance.

## Features

- **Core ALB Configuration**
  - Internal/External load balancer support
  - Access logging
  - Deletion protection
  - Security group management
  - IPv4 and IPv6 support

- **WAF Integration**
  - Web ACL configuration
  - Managed rule groups
  - Rate-based rules
  - IP set references
  - Custom rules
  - Visibility configuration

- **Listener Management**
  - HTTP/HTTPS listeners
  - SSL/TLS configuration
  - Dynamic listener rules
  - Path-based routing
  - Host-based routing
  - Header-based routing
  - Query string routing
  - Source IP routing

- **Target Group Configuration**
  - Health checks
  - Stickiness
  - Target group attachments
  - Multiple target types
  - Weighted routing

- **Monitoring and Alerts**
  - CloudWatch dashboard
  - Metric math calculations
  - Performance monitoring
  - Error rate tracking
  - Latency monitoring
  - Health status tracking
  - SNS notifications

## Module Structure

```
modules/alb/
├── alb/              # Core ALB resources
├── waf/              # WAF configuration
├── listeners/        # Listener and target group management
├── monitoring/       # CloudWatch monitoring
└── main.tf          # Main module orchestration
```

## Usage

```hcl
module "alb" {
  source = "./modules/alb"

  environment = "prod"
  vpc_id      = "vpc-123456"
  subnet_ids  = ["subnet-123456", "subnet-789012"]

  # ALB Configuration
  internal                = false
  enable_deletion_protection = true
  alb_logs_bucket_id      = "my-alb-logs-bucket"
  
  # Security Configuration
  allowed_cidr_blocks = [
    {
      cidr_block  = "10.0.0.0/16"
      port        = 80
      protocol    = "http"
      description = "Internal HTTP access"
    },
    {
      cidr_block  = "10.0.0.0/16"
      port        = 443
      protocol    = "https"
      description = "Internal HTTPS access"
    }
  ]

  # WAF Configuration
  waf_default_action = "allow"
  waf_rules = {
    aws_managed_rules = {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 1
      action   = "block"
      statement = {
        managed_rule_group = {
          name        = "AWSManagedRulesCommonRuleSet"
          vendor_name = "AWS"
        }
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name               = "AWSManagedRulesCommonRuleSet"
        sampled_requests_enabled  = true
      }
    }
  }

  # Listener Configuration
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type = "redirect"
        redirect = {
          port        = "443"
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      }
    },
    https = {
      port     = 443
      protocol = "HTTPS"
      certificate_arn = "arn:aws:acm:region:account:certificate/certificate-id"
      ssl_policy = "ELBSecurityPolicy-2016-08"
      default_action = {
        type = "forward"
      }
    }
  }

  # Listener Rules
  listener_rules = {
    api_route = {
      listener_key = "https"
      priority     = 1
      action = {
        type = "forward"
      }
      condition = {
        path_pattern = {
          values = ["/api/*"]
        }
      }
    }
  }

  # Target Group Configuration
  target_port = 8080
  target_protocol = "HTTP"
  health_check = {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher            = "200"
    path               = "/health"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 2
  }
  stickiness = {
    enabled         = true
    cookie_duration = 86400
    type           = "lb_cookie"
  }

  # Monitoring Configuration
  http_5xx_error_threshold    = 5
  target_response_time_threshold = 5
  sns_topic_arn               = "arn:aws:sns:region:account:topic-name"

  tags = {
    Environment = "prod"
    Project     = "my-project"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name | `string` | n/a | yes |
| vpc_id | ID of the VPC | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for the ALB | `list(string)` | n/a | yes |
| internal | Whether the ALB is internal | `bool` | `false` | no |
| enable_deletion_protection | Whether to enable deletion protection | `bool` | `true` | no |
| alb_logs_bucket_id | ID of the S3 bucket for ALB logs | `string` | n/a | yes |
| allowed_cidr_blocks | List of allowed CIDR blocks | `list(object)` | `[]` | no |
| allowed_ipv6_cidr_blocks | List of allowed IPv6 CIDR blocks | `list(object)` | `[]` | no |
| vpc_cidr | CIDR block of the VPC | `string` | n/a | yes |
| app_security_group_id | ID of the application security group | `string` | n/a | yes |
| target_port | Port on which targets receive traffic | `number` | `80` | no |
| target_protocol | Protocol for targets | `string` | `"HTTP"` | no |
| waf_default_action | Default action for WAF | `string` | `"allow"` | no |
| waf_rules | Map of WAF rules | `map(object)` | `{}` | no |
| listeners | Map of listener configurations | `map(object)` | n/a | yes |
| listener_rules | Map of listener rules | `map(object)` | `{}` | no |
| health_check | Health check configuration | `object` | n/a | yes |
| stickiness | Stickiness configuration | `object` | n/a | yes |
| http_5xx_error_threshold | Threshold for 5XX errors | `number` | `5` | no |
| target_response_time_threshold | Threshold for target response time | `number` | `5` | no |
| sns_topic_arn | ARN of the SNS topic for alarms | `string` | n/a | yes |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_arn | The ARN of the ALB |
| alb_dns_name | The DNS name of the ALB |
| alb_zone_id | The canonical hosted zone ID of the ALB |
| alb_arn_suffix | The ARN suffix of the ALB |
| target_group_arn | The ARN of the target group |
| target_group_arn_suffix | The ARN suffix of the target group |
| listener_arns | A map of listener ARNs |
| listener_rule_arns | A map of listener rule ARNs |
| waf_web_acl_arn | The ARN of the WAF Web ACL |
| cloudwatch_dashboard_arn | The ARN of the CloudWatch dashboard |

## Security Considerations

- The module implements security best practices:
  - WAF integration for web application protection
  - Granular security group rules
  - SSL/TLS support
  - Access logging
  - Deletion protection

## Monitoring

The module creates a comprehensive CloudWatch dashboard with the following widgets:
- Request metrics and success rate
- Response time percentiles
- Host health status
- Throughput metrics
- Error rate analysis
- Latency distribution


## Additional Resources

- [AWS ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html)
- [AWS WAF Documentation](https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) 