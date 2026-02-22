# WAF Configuration
resource "aws_wafv2_web_acl" "main" {
  name        = "${var.project}-${var.environment}-waf"
  description = "WAF Web ACL for ${var.project}-${var.environment}"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled  = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "AWSManagedRulesKnownBadInputsRuleSetMetric"
      sampled_requests_enabled  = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "WAFWebACLMetric"
    sampled_requests_enabled  = true
  }

  tags = var.tags
}

# Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

# AWS Shield Advanced
resource "aws_shield_protection" "alb" {
  name         = "${var.project}-${var.environment}-shield"
  resource_arn = var.alb_arn

  tags = var.tags
}

# GuardDuty Configuration
resource "aws_guardduty_detector" "main" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = var.tags
}

# GuardDuty S3 Protection
resource "aws_guardduty_s3_protection" "main" {
  detector_id = aws_guardduty_detector.main.id
  enable      = true
}

# GuardDuty Malware Protection
resource "aws_guardduty_malware_protection" "main" {
  detector_id = aws_guardduty_detector.main.id
  scan_ec2_instance_with_findings {
    ebs_volumes {
      enable = true
    }
  }
}

# Security Hub Configuration
resource "aws_securityhub_account" "main" {
  enable_default_standards = true
  auto_enable_controls    = true
}

resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
  depends_on    = [aws_securityhub_account.main]
}

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.main]
}

# Security Hub Product Subscriptions
resource "aws_securityhub_product_subscription" "guardduty" {
  product_arn = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/guardduty"
  depends_on  = [aws_securityhub_account.main]
}

resource "aws_securityhub_product_subscription" "inspector" {
  product_arn = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/inspector"
  depends_on  = [aws_securityhub_account.main]
}

# CloudWatch Alarms for Security Events
resource "aws_cloudwatch_metric_alarm" "guardduty_findings" {
  alarm_name          = "${var.project}-${var.environment}-guardduty-findings"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "TotalFindingCount"
  namespace           = "AWS/GuardDuty"
  period             = "300"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description  = "This metric monitors GuardDuty findings"
  alarm_actions      = [var.alarm_sns_topic_arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "waf_blocked_requests" {
  alarm_name          = "${var.project}-${var.environment}-waf-blocked-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period             = "300"
  statistic          = "Sum"
  threshold          = "100"
  alarm_description  = "This metric monitors WAF blocked requests"
  alarm_actions      = [var.alarm_sns_topic_arn]

  dimensions = {
    WebACL = aws_wafv2_web_acl.main.name
    Region = data.aws_region.current.name
  }

  tags = var.tags
}

# Data source for current region
data "aws_region" "current" {} 