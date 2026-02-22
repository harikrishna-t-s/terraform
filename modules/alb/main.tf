# Data sources for dynamic values
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "main" {}
data "aws_vpc" "main" {
  id = var.vpc_id
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get availability zones in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "${var.environment}-alb"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  access_logs {
    bucket  = var.alb_logs_bucket_id
    prefix  = "alb-logs"
    enabled = true
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-alb"
      Environment = var.environment
      Management  = "terraform"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# WAF Web ACL
resource "aws_wafv2_web_acl" "main" {
  name        = "${var.environment}-alb-waf"
  description = "WAF Web ACL for ALB"
  scope       = "REGIONAL"

  default_action {
    dynamic "allow" {
      for_each = var.waf_default_action == "allow" ? [1] : []
      content {}
    }
    dynamic "block" {
      for_each = var.waf_default_action == "block" ? [1] : []
      content {}
    }
  }

  dynamic "rule" {
    for_each = var.waf_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      dynamic "override_action" {
        for_each = rule.value.action == "none" ? [1] : []
        content {
          none {}
        }
      }

      dynamic "action" {
        for_each = rule.value.action != "none" ? [rule.value.action] : []
        content {
          dynamic "allow" {
            for_each = action.value == "allow" ? [1] : []
            content {}
          }
          dynamic "block" {
            for_each = action.value == "block" ? [1] : []
            content {}
          }
          dynamic "count" {
            for_each = action.value == "count" ? [1] : []
            content {}
          }
        }
      }

      statement {
        dynamic "managed_rule_group_statement" {
          for_each = rule.value.statement.managed_rule_group != null ? [rule.value.statement.managed_rule_group] : []
          content {
            name        = managed_rule_group_statement.value.name
            vendor_name = managed_rule_group_statement.value.vendor_name

            dynamic "excluded_rule" {
              for_each = managed_rule_group_statement.value.excluded_rules != null ? managed_rule_group_statement.value.excluded_rules : []
              content {
                name = excluded_rule.value
              }
            }
          }
        }

        dynamic "rate_based_statement" {
          for_each = rule.value.statement.rate_based != null ? [rule.value.statement.rate_based] : []
          content {
            limit              = rate_based_statement.value.limit
            aggregate_key_type = rate_based_statement.value.aggregate_key_type

            dynamic "scope_down_statement" {
              for_each = rate_based_statement.value.scope_down != null ? [rate_based_statement.value.scope_down] : []
              content {
                dynamic "ip_set_reference_statement" {
                  for_each = scope_down_statement.value.ip_set_reference_statement != null ? [scope_down_statement.value.ip_set_reference_statement] : []
                  content {
                    arn = ip_set_reference_statement.value.arn
                  }
                }
              }
            }
          }
        }

        dynamic "ip_set_reference_statement" {
          for_each = rule.value.statement.ip_set_reference != null ? [rule.value.statement.ip_set_reference] : []
          content {
            arn = ip_set_reference_statement.value.arn
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = rule.value.visibility_config.cloudwatch_metrics_enabled
        metric_name               = rule.value.visibility_config.metric_name
        sampled_requests_enabled  = rule.value.visibility_config.sampled_requests_enabled
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.waf_visibility_config.cloudwatch_metrics_enabled
    metric_name               = var.waf_visibility_config.metric_name
    sampled_requests_enabled  = var.waf_visibility_config.sampled_requests_enabled
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-alb-waf"
      Environment = var.environment
      Management  = "terraform"
    }
  )
}

# WAF Web ACL Association
resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = aws_lb.alb.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for ALB with granular access controls"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-alb-sg"
      Environment = var.environment
      Management  = "terraform"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Individual Security Group Rules for ALB
resource "aws_security_group_rule" "alb_ingress_http" {
  for_each = { for idx, rule in var.allowed_cidr_blocks : idx => rule if rule.protocol == "http" }

  type              = "ingress"
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = "tcp"
  cidr_blocks       = [each.value.cidr_block]
  description       = each.value.description
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_ingress_https" {
  for_each = { for idx, rule in var.allowed_cidr_blocks : idx => rule if rule.protocol == "https" }

  type              = "ingress"
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = "tcp"
  cidr_blocks       = [each.value.cidr_block]
  description       = each.value.description
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_ingress_ipv6_http" {
  for_each = { for idx, rule in var.allowed_ipv6_cidr_blocks : idx => rule if rule.protocol == "http" }

  type              = "ingress"
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = "tcp"
  ipv6_cidr_blocks  = [each.value.cidr_block]
  description       = each.value.description
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_ingress_ipv6_https" {
  for_each = { for idx, rule in var.allowed_ipv6_cidr_blocks : idx => rule if rule.protocol == "https" }

  type              = "ingress"
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = "tcp"
  ipv6_cidr_blocks  = [each.value.cidr_block]
  description       = each.value.description
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_ingress_health_check" {
  type              = "ingress"
  from_port         = var.target_port
  to_port           = var.target_port
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  description       = "Health check from VPC"
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_egress_app" {
  type                     = "egress"
  from_port                = var.target_port
  to_port                  = var.target_port
  protocol                 = "tcp"
  source_security_group_id = var.app_security_group_id
  description              = "Outbound to application servers"
  security_group_id        = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_egress_internet" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Outbound internet access"
  security_group_id = aws_security_group.alb.id
}

# Target Group
resource "aws_lb_target_group" "app" {
  name        = "${var.environment}-app-tg"
  port        = var.target_port
  protocol    = var.target_protocol
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = var.health_check.enabled
    healthy_threshold   = var.health_check.healthy_threshold
    interval            = var.health_check.interval
    matcher            = var.health_check.matcher
    path               = var.health_check.path
    port               = var.health_check.port
    protocol           = var.health_check.protocol
    timeout            = var.health_check.timeout
    unhealthy_threshold = var.health_check.unhealthy_threshold
  }

  stickiness {
    enabled         = var.stickiness.enabled
    cookie_duration = var.stickiness.cookie_duration
    type           = var.stickiness.type
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-app-tg"
      Environment = var.environment
      Management  = "terraform"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "main" {
  for_each = var.target_group_attachments

  target_group_arn  = aws_lb_target_group.app.arn
  target_id         = each.value.target_id
  port              = coalesce(each.value.port, var.target_group_attachment_port, var.target_port)
  availability_zone = coalesce(each.value.availability_zone, var.target_group_attachment_availability_zone)

  lifecycle {
    create_before_destroy = true
  }
}

# Dynamic Listener Resource
resource "aws_lb_listener" "main" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.alb.arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = each.value.protocol == "HTTPS" ? each.value.ssl_policy : null
  certificate_arn   = each.value.protocol == "HTTPS" ? each.value.certificate_arn : null

  dynamic "default_action" {
    for_each = [each.value.default_action]
    content {
      type = default_action.value.type

      dynamic "forward" {
        for_each = default_action.value.type == "forward" ? [default_action.value] : []
        content {
          target_group_arn = forward.value.target_group_arn != null ? forward.value.target_group_arn : aws_lb_target_group.app.arn
        }
      }

      dynamic "redirect" {
        for_each = default_action.value.type == "redirect" ? [default_action.value.redirect] : []
        content {
          port        = redirect.value.port
          protocol    = redirect.value.protocol
          status_code = redirect.value.status_code
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-alb-listener-${each.key}"
      Environment = var.environment
      Management  = "terraform"
    }
  )
}

# Dynamic Listener Rules
resource "aws_lb_listener_rule" "main" {
  for_each = var.listener_rules

  listener_arn = aws_lb_listener.main[each.value.listener_key].arn
  priority     = each.value.priority

  action {
    type             = each.value.action.type
    target_group_arn = each.value.action.type == "forward" ? (each.value.action.target_group_arn != null ? each.value.action.target_group_arn : aws_lb_target_group.app.arn) : null

    dynamic "fixed_response" {
      for_each = each.value.action.type == "fixed-response" ? [each.value.action.fixed_response] : []
      content {
        content_type = fixed_response.value.content_type
        message_body = fixed_response.value.message_body
        status_code  = fixed_response.value.status_code
      }
    }

    dynamic "redirect" {
      for_each = each.value.action.type == "redirect" ? [each.value.action.redirect] : []
      content {
        host        = redirect.value.host
        path        = redirect.value.path
        port        = redirect.value.port
        protocol    = redirect.value.protocol
        query       = redirect.value.query
        status_code = redirect.value.status_code
      }
    }
  }

  dynamic "condition" {
    for_each = [
      for condition in [
        each.value.condition.host_header != null ? {
          type  = "host-header"
          value = condition.host_header
        } : null,
        each.value.condition.path_pattern != null ? {
          type  = "path-pattern"
          value = condition.path_pattern
        } : null,
        each.value.condition.http_header != null ? {
          type  = "http-header"
          value = condition.http_header
        } : null,
        each.value.condition.http_request_method != null ? {
          type  = "http-request-method"
          value = condition.http_request_method
        } : null,
        each.value.condition.query_string != null ? {
          type  = "query-string"
          value = each.value.condition.query_string
        } : null,
        each.value.condition.source_ip != null ? {
          type  = "source-ip"
          value = condition.source_ip
        } : null
      ] : condition if condition != null
    ]
    content {
      dynamic "host_header" {
        for_each = condition.value.type == "host-header" ? [condition.value.value] : []
        content {
          values = host_header.value.values
        }
      }

      dynamic "path_pattern" {
        for_each = condition.value.type == "path-pattern" ? [condition.value.value] : []
        content {
          values = path_pattern.value.values
        }
      }

      dynamic "http_header" {
        for_each = condition.value.type == "http-header" ? [condition.value.value] : []
        content {
          http_header_name = http_header.value.http_header_name
          values          = http_header.value.values
        }
      }

      dynamic "http_request_method" {
        for_each = condition.value.type == "http-request-method" ? [condition.value.value] : []
        content {
          values = http_request_method.value.values
        }
      }

      dynamic "query_string" {
        for_each = condition.value.type == "query-string" ? [condition.value.value] : []
        content {
          key   = query_string.value.key
          value = query_string.value.value
        }
      }

      dynamic "source_ip" {
        for_each = condition.value.type == "source-ip" ? [condition.value.value] : []
        content {
          values = source_ip.value.values
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-alb-listener-rule-${each.key}"
      Environment = var.environment
      Management  = "terraform"
    }
  )
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "http_5xx_errors" {
  alarm_name          = "${var.environment}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period             = "300"
  statistic          = "Sum"
  threshold          = var.http_5xx_error_threshold
  alarm_description  = "This metric monitors ALB 5XX errors"
  alarm_actions      = [var.sns_topic_arn]

  dimensions = {
    LoadBalancer = aws_lb.alb.arn_suffix
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-alb-5xx-errors"
      Environment = var.environment
      Management  = "terraform"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "target_response_time" {
  alarm_name          = "${var.environment}-alb-target-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period             = "300"
  statistic          = "Average"
  threshold          = var.target_response_time_threshold
  alarm_description  = "This metric monitors ALB target response time"
  alarm_actions      = [var.sns_topic_arn]

  dimensions = {
    LoadBalancer = aws_lb.alb.arn_suffix
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-alb-target-response-time"
      Environment = var.environment
      Management  = "terraform"
    }
  )
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "alb" {
  dashboard_name = "${var.environment}-alb-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Request Metrics Widget
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.alb.arn_suffix, { label = "Total Requests" }],
            ["AWS/ApplicationELB", "HTTPCode_ELB_4XX_Count", "LoadBalancer", aws_lb.alb.arn_suffix, { label = "4XX Errors" }],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", aws_lb.alb.arn_suffix, { label = "5XX Errors" }],
            [{ expression = "SUM([m1, m2, m3])", label = "Total Errors", id = "e1" }],
            [{ expression = "m1 / (m1 + e1) * 100", label = "Success Rate (%)", id = "e2" }]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Request Metrics and Success Rate"
          yAxis = {
            left = {
              min = 0
              max = 100
              showUnits = false
            }
          }
        }
      },

      # Response Time Widget
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.alb.arn_suffix, { label = "Average Response Time" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.alb.arn_suffix, { stat = "p95", label = "95th Percentile" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.alb.arn_suffix, { stat = "p99", label = "99th Percentile" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Response Time Percentiles"
          yAxis = {
            left = {
              min = 0
              showUnits = true
            }
          }
        }
      },

      # Health Status Widget
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", aws_lb.alb.arn_suffix, { label = "Healthy Hosts" }],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", aws_lb.alb.arn_suffix, { label = "Unhealthy Hosts" }],
            [{ expression = "m1 / (m1 + m2) * 100", label = "Health Rate (%)", id = "e1" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Host Health Status"
          yAxis = {
            left = {
              min = 0
              max = 100
              showUnits = false
            }
          }
        }
      },

      # Throughput Widget
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "ProcessedBytes", "LoadBalancer", aws_lb.alb.arn_suffix, { label = "Processed Bytes" }],
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.alb.arn_suffix, { label = "Request Count" }],
            [{ expression = "m1 / m2", label = "Avg Bytes per Request", id = "e1" }],
            [{ expression = "m2 / 300", label = "Requests per Second", id = "e2" }]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Throughput Metrics"
          yAxis = {
            left = {
              min = 0
              showUnits = true
            }
          }
        }
      },

      # Error Rate Widget
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_4XX_Count", "LoadBalancer", aws_lb.alb.arn_suffix, { label = "4XX Errors" }],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", aws_lb.alb.arn_suffix, { label = "5XX Errors" }],
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.alb.arn_suffix, { label = "Total Requests" }],
            [{ expression = "(m1 + m2) / m3 * 100", label = "Error Rate (%)", id = "e1" }]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Error Rate Analysis"
          yAxis = {
            left = {
              min = 0
              max = 100
              showUnits = false
            }
          }
        }
      },

      # Latency Distribution Widget
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "Latency", "LoadBalancer", aws_lb.alb.arn_suffix, { stat = "p50", label = "50th Percentile" }],
            ["AWS/ApplicationELB", "Latency", "LoadBalancer", aws_lb.alb.arn_suffix, { stat = "p90", label = "90th Percentile" }],
            ["AWS/ApplicationELB", "Latency", "LoadBalancer", aws_lb.alb.arn_suffix, { stat = "p95", label = "95th Percentile" }],
            ["AWS/ApplicationELB", "Latency", "LoadBalancer", aws_lb.alb.arn_suffix, { stat = "p99", label = "99th Percentile" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Latency Distribution"
          yAxis = {
            left = {
              min = 0
              showUnits = true
            }
          }
        }
      }
    ]
  })
}

module "alb" {
  source = "./alb"

  environment              = var.environment
  vpc_id                  = var.vpc_id
  subnet_ids              = var.subnet_ids
  internal                = var.internal
  enable_deletion_protection = var.enable_deletion_protection
  alb_logs_bucket_id      = var.alb_logs_bucket_id
  allowed_cidr_blocks     = var.allowed_cidr_blocks
  allowed_ipv6_cidr_blocks = var.allowed_ipv6_cidr_blocks
  vpc_cidr                = var.vpc_cidr
  app_security_group_id   = var.app_security_group_id
  target_port             = var.target_port
  tags                    = var.tags
}

module "waf" {
  source = "./waf"

  environment           = var.environment
  alb_arn              = module.alb.alb_arn
  waf_default_action   = var.waf_default_action
  waf_rules            = var.waf_rules
  waf_visibility_config = var.waf_visibility_config
  tags                 = var.tags
}

module "listeners" {
  source = "./listeners"

  environment                        = var.environment
  alb_arn                           = module.alb.alb_arn
  vpc_id                            = var.vpc_id
  target_port                       = var.target_port
  target_protocol                   = var.target_protocol
  health_check                      = var.health_check
  stickiness                        = var.stickiness
  target_group_attachments          = var.target_group_attachments
  target_group_attachment_port      = var.target_group_attachment_port
  target_group_attachment_availability_zone = var.target_group_attachment_availability_zone
  listeners                         = var.listeners
  listener_rules                    = var.listener_rules
  tags                             = var.tags
}

module "monitoring" {
  source = "./monitoring"

  environment                  = var.environment
  alb_arn_suffix              = module.alb.alb_arn_suffix
  region                      = data.aws_region.current.name
  http_5xx_error_threshold    = var.http_5xx_error_threshold
  target_response_time_threshold = var.target_response_time_threshold
  sns_topic_arn               = var.sns_topic_arn
  tags                        = var.tags
} 