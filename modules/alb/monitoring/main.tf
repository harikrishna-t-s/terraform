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
    LoadBalancer = var.alb_arn_suffix
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
    LoadBalancer = var.alb_arn_suffix
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
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { label = "Total Requests" }],
            ["AWS/ApplicationELB", "HTTPCode_ELB_4XX_Count", "LoadBalancer", var.alb_arn_suffix, { label = "4XX Errors" }],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { label = "5XX Errors" }],
            [{ expression = "SUM([m1, m2, m3])", label = "Total Errors", id = "e1" }],
            [{ expression = "m1 / (m1 + e1) * 100", label = "Success Rate (%)", id = "e2" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.region
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
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { label = "Average Response Time" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p95", label = "95th Percentile" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p99", label = "99th Percentile" }]
          ]
          period = 300
          stat   = "Average"
          region = var.region
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
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", var.alb_arn_suffix, { label = "Healthy Hosts" }],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", var.alb_arn_suffix, { label = "Unhealthy Hosts" }],
            [{ expression = "m1 / (m1 + m2) * 100", label = "Health Rate (%)", id = "e1" }]
          ]
          period = 300
          stat   = "Average"
          region = var.region
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
            ["AWS/ApplicationELB", "ProcessedBytes", "LoadBalancer", var.alb_arn_suffix, { label = "Processed Bytes" }],
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { label = "Request Count" }],
            [{ expression = "m1 / m2", label = "Avg Bytes per Request", id = "e1" }],
            [{ expression = "m2 / 300", label = "Requests per Second", id = "e2" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.region
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
            ["AWS/ApplicationELB", "HTTPCode_ELB_4XX_Count", "LoadBalancer", var.alb_arn_suffix, { label = "4XX Errors" }],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { label = "5XX Errors" }],
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { label = "Total Requests" }],
            [{ expression = "(m1 + m2) / m3 * 100", label = "Error Rate (%)", id = "e1" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.region
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
            ["AWS/ApplicationELB", "Latency", "LoadBalancer", var.alb_arn_suffix, { stat = "p50", label = "50th Percentile" }],
            ["AWS/ApplicationELB", "Latency", "LoadBalancer", var.alb_arn_suffix, { stat = "p90", label = "90th Percentile" }],
            ["AWS/ApplicationELB", "Latency", "LoadBalancer", var.alb_arn_suffix, { stat = "p95", label = "95th Percentile" }],
            ["AWS/ApplicationELB", "Latency", "LoadBalancer", var.alb_arn_suffix, { stat = "p99", label = "99th Percentile" }]
          ]
          period = 300
          stat   = "Average"
          region = var.region
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