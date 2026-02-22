# Centralized Logging
resource "aws_cloudwatch_log_group" "central" {
  name              = "/aws/${var.project}/${var.environment}/central"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.logs.arn

  tags = var.tags
}

# KMS Key for Log Encryption
resource "aws_kms_key" "logs" {
  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.tags
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${var.project}-${var.environment}-logs"
  target_key_id = aws_kms_key.logs.key_id
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", "*"],
            ["AWS/EC2", "NetworkIn", "InstanceId", "*"],
            ["AWS/EC2", "NetworkOut", "InstanceId", "*"]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "EC2 Metrics"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "*"],
            ["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", "*"],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "*"]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "RDS Metrics"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "*"],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "*"],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "*"]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "ALB Metrics"
        }
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "This metric monitors EC2 CPU utilization"
  alarm_actions      = [var.alarm_sns_topic_arn]

  dimensions = {
    InstanceId = "*"
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "${var.project}-${var.environment}-high-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period             = "300"
  statistic          = "Average"
  threshold          = "1000000000"  # 1GB
  alarm_description  = "This metric monitors RDS freeable memory"
  alarm_actions      = [var.alarm_sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = "*"
  }

  tags = var.tags
}

# Cost Management
resource "aws_budgets_budget" "monthly" {
  name              = "${var.project}-${var.environment}-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.monthly_budget_limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  include_credit    = true
  include_discount  = true
  include_other_subscription = true
  include_recurring = true
  include_refund    = true
  include_subscription = true
  include_support   = true
  include_tax       = true
  include_upfront   = true

  notification {
    comparison_operator = "GREATER_THAN"
    threshold          = 80
    threshold_type     = "PERCENTAGE"
    notification_type  = "ACTUAL"
    subscriber_email_addresses = [var.budget_notification_email]
  }

  notification {
    comparison_operator = "GREATER_THAN"
    threshold          = 100
    threshold_type     = "PERCENTAGE"
    notification_type  = "ACTUAL"
    subscriber_email_addresses = [var.budget_notification_email]
  }
}

# Resource Scheduling
resource "aws_ssm_maintenance_window" "resource_scheduling" {
  name              = "${var.project}-${var.environment}-resource-scheduling"
  description       = "Maintenance window for resource scheduling"
  schedule          = "cron(0 0 ? * SUN *)"  # Every Sunday at midnight
  duration          = 4
  cutoff            = 1
  allow_unassociated_targets = false

  tags = var.tags
}

# CloudWatch Log Metric Filters
resource "aws_cloudwatch_log_metric_filter" "error_logs" {
  name           = "${var.project}-${var.environment}-error-logs"
  pattern        = "{ $.level = \"ERROR\" }"
  log_group_name = aws_cloudwatch_log_group.central.name

  metric_transformation {
    name          = "ErrorCount"
    namespace     = "LogMetrics"
    value         = "1"
    default_value = "0"
  }
}

# CloudWatch Alarm for Error Logs
resource "aws_cloudwatch_metric_alarm" "error_logs" {
  alarm_name          = "${var.project}-${var.environment}-error-logs"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ErrorCount"
  namespace           = "LogMetrics"
  period             = "300"
  statistic          = "Sum"
  threshold          = "10"
  alarm_description  = "This metric monitors error logs"
  alarm_actions      = [var.alarm_sns_topic_arn]

  tags = var.tags
}

# CloudWatch Log Subscription for Centralized Logging
resource "aws_cloudwatch_log_subscription_filter" "central" {
  name            = "${var.project}-${var.environment}-log-subscription"
  log_group_name  = aws_cloudwatch_log_group.central.name
  filter_pattern  = ""
  destination_arn = var.log_destination_arn
  distribution    = "Random"
}

# CloudWatch Event Rules for Resource Scheduling
resource "aws_cloudwatch_event_rule" "resource_scheduling" {
  name                = "${var.project}-${var.environment}-resource-scheduling"
  description         = "Schedule for resource management"
  schedule_expression = "cron(0 0 ? * SUN *)"  # Every Sunday at midnight
}

resource "aws_cloudwatch_event_target" "resource_scheduling" {
  rule      = aws_cloudwatch_event_rule.resource_scheduling.name
  target_id = "ResourceScheduling"
  arn       = aws_ssm_maintenance_window.resource_scheduling.arn
  role_arn  = aws_iam_role.event_bridge_role.arn
}

# IAM Role for EventBridge
resource "aws_iam_role" "event_bridge_role" {
  name = "${var.project}-${var.environment}-event-bridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "event_bridge_policy" {
  name = "${var.project}-${var.environment}-event-bridge-policy"
  role = aws_iam_role.event_bridge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:StartAutomationExecution",
          "ssm:GetAutomationExecution"
        ]
        Resource = "*"
      }
    ]
  })
}

# Data source for current region
data "aws_region" "current" {} 