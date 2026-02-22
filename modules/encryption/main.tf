# KMS Key for Data Encryption
resource "aws_kms_key" "data" {
  description             = "KMS key for ${var.project}-${var.environment}-data"
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
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      },
      {
        Sid    = "Allow RDS"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_kms_alias" "data" {
  name          = "alias/${var.project}-${var.environment}-data"
  target_key_id = aws_kms_key.data.key_id
}

# CloudWatch Log Group with Encryption
resource "aws_cloudwatch_log_group" "encrypted" {
  name              = "/aws/${var.project}/${var.environment}/encrypted"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.data.arn

  tags = var.tags
}

# S3 Bucket with Encryption
resource "aws_s3_bucket" "encrypted" {
  bucket = "${var.project}-${var.environment}-encrypted-data"

  tags = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypted" {
  bucket = aws_s3_bucket.encrypted.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.data.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "encrypted" {
  bucket = aws_s3_bucket.encrypted.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "encrypted" {
  bucket = aws_s3_bucket.encrypted.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# RDS Instance with Encryption
resource "aws_db_instance" "encrypted" {
  identifier        = "${var.project}-${var.environment}-encrypted"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "encrypteddb"
  username = "admin"
  password = var.db_password

  storage_encrypted = true
  kms_key_id        = aws_kms_key.data.arn

  backup_retention_period = 7
  skip_final_snapshot    = true

  tags = var.tags
}

# CloudWatch Alarms for KMS
resource "aws_cloudwatch_metric_alarm" "kms_usage" {
  alarm_name          = "${var.project}-${var.environment}-kms-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "KeyUsage"
  namespace           = "AWS/KMS"
  period             = "300"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description  = "This metric monitors KMS key usage"
  alarm_actions      = [var.alarm_sns_topic_arn]

  dimensions = {
    KeyId = aws_kms_key.data.key_id
  }

  tags = var.tags
}

# VPC Endpoint for KMS
resource "aws_vpc_endpoint" "kms" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  private_dns_enabled = true

  tags = var.tags
}

# Security Group for VPC Endpoint
resource "aws_security_group" "vpc_endpoint" {
  name        = "${var.project}-${var.environment}-kms-endpoint"
  description = "Security group for KMS VPC endpoint"
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