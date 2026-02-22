# AWS GuardDuty
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

# AWS Config
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project}-${var.environment}-config-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported = true
    include_global_resources = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "${var.project}-${var.environment}-config-delivery"
  s3_bucket_name = var.config_bucket_name
  s3_key_prefix  = "config"
  sns_topic_arn  = var.config_sns_topic_arn

  depends_on = [aws_config_configuration_recorder.main]
}

# AWS Config Rules
resource "aws_config_config_rule" "s3_bucket_encryption" {
  name        = "${var.project}-${var.environment}-s3-bucket-encryption"
  description = "Checks if S3 buckets have server-side encryption enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "rds_encryption" {
  name        = "${var.project}-${var.environment}-rds-encryption"
  description = "Checks if RDS instances have encryption enabled"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "iam_password_policy" {
  name        = "${var.project}-${var.environment}-iam-password-policy"
  description = "Checks if IAM password policy meets requirements"

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  input_parameters = jsonencode({
    RequireUppercaseCharacters = true
    RequireLowercaseCharacters = true
    RequireNumbers            = true
    RequireSymbols            = true
    MinimumPasswordLength     = 14
    PasswordReusePrevention   = 24
    MaxPasswordAge           = 90
  })

  depends_on = [aws_config_configuration_recorder.main]
}

# IAM Role for AWS Config
resource "aws_iam_role" "config" {
  name = "${var.project}-${var.environment}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "config" {
  name = "${var.project}-${var.environment}-config-policy"
  role = aws_iam_role.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.config_bucket_name}",
          "arn:aws:s3:::${var.config_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:GetTopicAttributes",
          "sns:ListTopics"
        ]
        Resource = var.config_sns_topic_arn
      },
      {
        Effect = "Allow"
        Action = [
          "config:Put*",
          "config:Get*",
          "config:List*",
          "config:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Security Hub
resource "aws_securityhub_account" "main" {
  enable_default_standards = true
  auto_enable_controls    = true
}

# Security Hub Standards
resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
  depends_on    = [aws_securityhub_account.main]
}

resource "aws_securityhub_standards_subscription" "pci" {
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/pci-dss/v/3.2.1"
  depends_on    = [aws_securityhub_account.main]
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

resource "aws_cloudwatch_metric_alarm" "config_compliance" {
  alarm_name          = "${var.project}-${var.environment}-config-compliance"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ComplianceScore"
  namespace           = "AWS/Config"
  period             = "300"
  statistic          = "Average"
  threshold          = "100"
  alarm_description  = "This metric monitors AWS Config compliance score"
  alarm_actions      = [var.alarm_sns_topic_arn]

  tags = var.tags
}

# Data sources
data "aws_region" "current" {} 