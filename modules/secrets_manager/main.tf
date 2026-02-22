locals {
  name_prefix = "${var.project}-${var.environment}"
  
  # Common tags
  common_tags = merge(
    var.common_tags,
    {
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "Terraform"
      Service     = "secrets-manager"
    }
  )

  # Secret tags
  secret_tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-${var.secret_name}"
    }
  )

  # Rotation strategy configuration
  rotation_config = {
    single_user = {
      schedule_expression = "rate(30 days)"
      rotation_lambda_name = "SecretsManagerRotationSingleUser"
    }
    alternating_users = {
      schedule_expression = "rate(30 days)"
      rotation_lambda_name = "SecretsManagerRotationAlternatingUsers"
    }
    custom = {
      schedule_expression = var.rotation_schedule
      rotation_lambda_name = var.custom_rotation_lambda_name
    }
  }

  # Get rotation configuration based on strategy
  current_rotation = local.rotation_config[var.rotation_strategy]

  # Determine whether to use Parameter Store or Secrets Manager
  use_parameter_store = var.use_parameter_store && var.parameter_type != "SecureString"
}

# Dedicated KMS Key for Secrets Manager
resource "aws_kms_key" "secrets" {
  description             = "KMS key for Secrets Manager in ${var.environment} environment"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_policy.json
  tags                    = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${local.name_prefix}-secrets-manager-key"
  target_key_id = aws_kms_key.secrets.key_id
}

# KMS Policy Document
data "aws_iam_policy_document" "kms_policy" {
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
      type = "Service"
      identifiers = ["secretsmanager.amazonaws.com"]
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
  }
}

# IAM Policy Document for Secrets Manager Access
data "aws_iam_policy_document" "secrets_access" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [aws_secretsmanager_secret.main.arn]
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

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage"
    ]
    resources = [aws_secretsmanager_secret.main.arn]
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
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }
}

# IAM Policy for Secrets Manager Access
resource "aws_iam_policy" "secrets_access" {
  name        = "${local.name_prefix}-secrets-access"
  description = "Policy for accessing Secrets Manager secrets"
  policy      = data.aws_iam_policy_document.secrets_access.json
  tags        = local.common_tags
}

# IAM Role for Secret Rotation
data "aws_iam_policy_document" "rotation_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "rotation" {
  name               = "${local.name_prefix}-secrets-rotation"
  assume_role_policy = data.aws_iam_policy_document.rotation_assume_role.json
  tags               = local.common_tags
}

# IAM Policy for Secret Rotation
data "aws_iam_policy_document" "rotation" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage"
    ]
    resources = [aws_secretsmanager_secret.main.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  # Add additional permissions based on rotation strategy
  dynamic "statement" {
    for_each = var.rotation_strategy == "custom" ? [1] : []
    content {
      effect = "Allow"
      actions = var.custom_rotation_permissions
      resources = var.custom_rotation_resources
    }
  }
}

resource "aws_iam_policy" "rotation" {
  name        = "${local.name_prefix}-secrets-rotation"
  description = "Policy for rotating Secrets Manager secrets"
  policy      = data.aws_iam_policy_document.rotation.json
  tags        = local.common_tags
}

resource "aws_iam_role_policy_attachment" "rotation" {
  role       = aws_iam_role.rotation.name
  policy_arn = aws_iam_policy.rotation.arn
}

# Lambda Function for Secret Rotation
resource "aws_lambda_function" "rotation" {
  filename         = var.rotation_strategy == "custom" ? var.rotation_lambda_zip : null
  function_name    = "${local.name_prefix}-secrets-rotation"
  role            = aws_iam_role.rotation.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 30
  memory_size     = 128

  # Use AWS managed rotation function for built-in strategies
  image_uri = var.rotation_strategy != "custom" ? "public.ecr.aws/aws-secrets-manager/aws-secrets-manager-rotation-${local.current_rotation.rotation_lambda_name}:latest" : null

  environment {
    variables = {
      SECRET_ARN = aws_secretsmanager_secret.main.arn
      ROTATION_TYPE = var.rotation_strategy
    }
  }

  tags = local.common_tags
}

# Secrets Manager Secret
resource "aws_secretsmanager_secret" "main" {
  name        = "${local.name_prefix}-${var.secret_name}"
  description = var.secret_description
  kms_key_id  = aws_kms_key.secrets.key_id

  tags = local.secret_tags
}

# Initial Secret Value
resource "aws_secretsmanager_secret_version" "main" {
  secret_id     = aws_secretsmanager_secret.main.id
  secret_string = var.initial_secret_value

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Secret Rotation Configuration
resource "aws_secretsmanager_secret_rotation" "main" {
  secret_id           = aws_secretsmanager_secret.main.id
  rotation_lambda_arn = aws_lambda_function.rotation.arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }

  depends_on = [
    aws_lambda_function.rotation,
    aws_secretsmanager_secret_version.main
  ]
}

# CloudWatch Log Group for Rotation Lambda
resource "aws_cloudwatch_log_group" "rotation" {
  name              = "/aws/lambda/${aws_lambda_function.rotation.function_name}"
  retention_in_days = 30
  tags              = local.common_tags
}

# CloudWatch Alarm for Secret Rotation
resource "aws_cloudwatch_metric_alarm" "rotation" {
  alarm_name          = "${local.name_prefix}-secrets-rotation"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period             = "300"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description  = "This metric monitors secret rotation errors"
  alarm_actions      = [var.alarm_sns_topic_arn]
  ok_actions         = [var.alarm_sns_topic_arn]

  dimensions = {
    FunctionName = aws_lambda_function.rotation.function_name
  }

  tags = local.common_tags
}

# KMS Key for Secret Encryption
resource "aws_kms_key" "secret" {
  description             = "KMS key for ${var.project}-${var.environment}-${var.secret_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Secrets Manager to use the key"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_kms_alias" "secret" {
  name          = "alias/${var.project}-${var.environment}-${var.secret_name}"
  target_key_id = aws_kms_key.secret.key_id
}

# Secrets Manager Secret
resource "aws_secretsmanager_secret" "secret" {
  name        = "${var.project}-${var.environment}-${var.secret_name}"
  description = var.secret_description
  kms_key_id  = aws_kms_key.secret.key_id

  recovery_window_in_days = var.recovery_window_in_days

  tags = var.tags
}

# Secret Version
resource "aws_secretsmanager_secret_version" "secret" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = var.initial_secret_value
}

# IAM Policy for Secret Access
resource "aws_iam_policy" "secret_access" {
  name        = "${var.project}-${var.environment}-${var.secret_name}-access"
  description = "Policy for accessing ${var.secret_name} secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.secret.arn
        ]
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = var.organization_id
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = [
          aws_kms_key.secret.arn
        ]
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = var.organization_id
          }
        }
      }
    ]
  })

  tags = var.tags
}

# CloudWatch Alarms for Secret Access
resource "aws_cloudwatch_metric_alarm" "secret_access" {
  alarm_name          = "${var.project}-${var.environment}-${var.secret_name}-access"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "SecretAccessCount"
  namespace           = "AWS/SecretsManager"
  period             = "300"
  statistic          = "Sum"
  threshold          = "100"
  alarm_description  = "This metric monitors secret access frequency"
  alarm_actions      = [var.alarm_sns_topic_arn]

  dimensions = {
    SecretId = aws_secretsmanager_secret.secret.id
  }

  tags = var.tags
}

# VPC Endpoint for Secrets Manager
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  private_dns_enabled = true

  tags = var.tags
}

# Security Group for VPC Endpoint
resource "aws_security_group" "vpc_endpoint" {
  name        = "${var.project}-${var.environment}-secretsmanager-endpoint"
  description = "Security group for Secrets Manager VPC endpoint"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = var.tags
}

# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {} 