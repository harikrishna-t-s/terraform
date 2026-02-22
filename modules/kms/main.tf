locals {
  # Naming conventions
  name_prefix = "${var.project}-${var.environment}"
  
  # Common tags
  common_tags = merge(
    var.common_tags,
    {
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "Terraform"
      Service     = "kms"
    }
  )

  # Resource-specific tags
  s3_tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-s3-kms-key"
      Service = "s3"
    }
  )

  secrets_tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-secrets-kms-key"
      Service = "secrets-manager"
    }
  )

  alarm_tags = merge(
    local.common_tags,
    {
      Service = "monitoring"
    }
  )

  # Service principals
  service_principals = {
    s3              = "s3.amazonaws.com"
    secrets_manager = "secretsmanager.amazonaws.com"
    cloudwatch      = "monitoring.amazonaws.com"
  }
}

# IAM Role for S3 Access
data "aws_iam_policy_document" "s3_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [local.service_principals.s3]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.aws_account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpc"
      values   = [var.vpc_id]
    }
  }
}

resource "aws_iam_role" "s3_access" {
  name               = "${local.name_prefix}-s3-kms-access"
  assume_role_policy = data.aws_iam_policy_document.s3_assume_role.json
  tags               = local.s3_tags
}

# IAM Role for Secrets Manager Access
data "aws_iam_policy_document" "secrets_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [local.service_principals.secrets_manager]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.aws_account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpc"
      values   = [var.vpc_id]
    }
  }
}

resource "aws_iam_role" "secrets_access" {
  name               = "${local.name_prefix}-secrets-kms-access"
  assume_role_policy = data.aws_iam_policy_document.secrets_assume_role.json
  tags               = local.secrets_tags
}

# IAM Policy Document for S3 KMS Key
data "aws_iam_policy_document" "s3_kms" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:root"]
    }
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Allow S3 to use the key"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [aws_iam_role.s3_access.arn]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpc"
      values   = [var.vpc_id]
    }
    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = var.allowed_ip_ranges
    }
    condition {
      test     = "StringLike"
      variable = "aws:ResourceArn"
      values   = ["arn:aws:s3:::${var.s3_bucket_name}/*"]
    }
  }
}

# IAM Policy Document for Secrets Manager KMS Key
data "aws_iam_policy_document" "secrets_kms" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:root"]
    }
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Allow Secrets Manager to use the key"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [aws_iam_role.secrets_access.arn]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpc"
      values   = [var.vpc_id]
    }
    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = var.allowed_ip_ranges
    }
  }
}

# KMS Key for S3 Encryption
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 encryption in ${var.environment} environment"
  deletion_window_in_days = var.key_deletion_window
  enable_key_rotation     = var.key_rotation_enabled
  policy                  = data.aws_iam_policy_document.s3_kms.json
  tags                    = local.s3_tags

  lifecycle {
    prevent_destroy = true
  }
}

# KMS Alias for S3 Key
resource "aws_kms_alias" "s3" {
  name          = "alias/${local.name_prefix}-s3-encryption-key"
  target_key_id = aws_kms_key.s3.key_id
}

# KMS Key for Secrets Manager
resource "aws_kms_key" "secrets" {
  description             = "KMS key for Secrets Manager in ${var.environment} environment"
  deletion_window_in_days = var.key_deletion_window
  enable_key_rotation     = var.key_rotation_enabled
  policy                  = data.aws_iam_policy_document.secrets_kms.json
  tags                    = local.secrets_tags

  lifecycle {
    prevent_destroy = true
  }
}

# KMS Alias for Secrets Manager Key
resource "aws_kms_alias" "secrets" {
  name          = "alias/${local.name_prefix}-secrets-manager-key"
  target_key_id = aws_kms_key.secrets.key_id
}

# CloudWatch Alarms for KMS Key Usage
resource "aws_cloudwatch_metric_alarm" "kms_s3_key_usage" {
  alarm_name          = "${local.name_prefix}-s3-kms-key-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "KeyUsage"
  namespace           = "AWS/KMS"
  period             = var.alarm_period
  statistic          = "Sum"
  threshold          = var.alarm_threshold
  alarm_description  = "This metric monitors KMS key usage for S3 encryption in ${var.environment} environment"
  alarm_actions      = [aws_sns_topic.kms_alerts.arn]
  ok_actions         = [aws_sns_topic.kms_alerts.arn]

  dimensions = {
    KeyId = aws_kms_key.s3.key_id
  }

  tags = merge(
    local.alarm_tags,
    {
      Name = "${local.name_prefix}-s3-kms-usage-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "kms_secrets_key_usage" {
  alarm_name          = "${local.name_prefix}-secrets-kms-key-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "KeyUsage"
  namespace           = "AWS/KMS"
  period             = var.alarm_period
  statistic          = "Sum"
  threshold          = var.alarm_threshold
  alarm_description  = "This metric monitors KMS key usage for Secrets Manager in ${var.environment} environment"
  alarm_actions      = [aws_sns_topic.kms_alerts.arn]
  ok_actions         = [aws_sns_topic.kms_alerts.arn]

  dimensions = {
    KeyId = aws_kms_key.secrets.key_id
  }

  tags = merge(
    local.alarm_tags,
    {
      Name = "${local.name_prefix}-secrets-kms-usage-alarm"
    }
  )
}

# SNS Topic for KMS Alerts
resource "aws_sns_topic" "kms_alerts" {
  name = "${local.name_prefix}-kms-alerts"
  tags = merge(
    local.alarm_tags,
    {
      Name = "${local.name_prefix}-kms-alerts"
    }
  )
}

# SNS Topic Policy
data "aws_iam_policy_document" "sns_topic" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["monitoring.amazonaws.com"]
    }
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.kms_alerts.arn]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [var.aws_account_id]
    }
  }
}

resource "aws_sns_topic_policy" "kms_alerts" {
  arn    = aws_sns_topic.kms_alerts.arn
  policy = data.aws_iam_policy_document.sns_topic.json
}

# IAM Module for KMS Access
module "kms_iam" {
  source = "../iam"

  project         = var.project
  environment     = var.environment
  aws_account_id  = var.aws_account_id
  vpc_id          = var.vpc_id
  allowed_ip_ranges = var.allowed_ip_ranges
  s3_bucket_name  = var.s3_bucket_name
  s3_kms_key_arn  = aws_kms_key.s3.arn
  secrets_kms_key_arn = aws_kms_key.secrets.arn
  common_tags     = local.common_tags

  depends_on = [
    aws_kms_key.s3,
    aws_kms_key.secrets
  ]
} 