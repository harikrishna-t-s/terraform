# Data sources for dynamic values
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "main" {}

# Get default VPC information
data "aws_vpc" "default" {
  default = true
}

# Get availability zones in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

# Get KMS key information if provided
data "aws_kms_key" "provided" {
  count  = var.kms_key_arn != "" ? 1 : 0
  key_id = var.kms_key_arn
}

# Terraform State Bucket
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${local.name_prefix}-terraform-state"

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ALB Access Logs Bucket
resource "aws_s3_bucket" "alb_logs" {
  bucket = "${local.name_prefix}-alb-logs"

  tags = local.common_tags
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "cleanup_old_logs"
    status = "Enabled"

    expiration {
      days = var.alb_log_retention_days
    }
  }
}

# CloudTrail Logs Bucket
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "${local.name_prefix}-cloudtrail-logs"

  tags = local.common_tags
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      }
    ]
  })
}

# AWS Config Logs Bucket
resource "aws_s3_bucket" "config_logs" {
  bucket = "${local.name_prefix}-config-logs"

  tags = local.common_tags
}

resource "aws_s3_bucket_policy" "config_logs" {
  bucket = aws_s3_bucket.config_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.config_logs.arn}/*",
          aws_s3_bucket.config_logs.arn
        ]
      }
    ]
  })
}

# Application Logs Bucket
resource "aws_s3_bucket" "app_logs" {
  bucket = "${local.name_prefix}-app-logs"

  tags = local.common_tags
}

resource "aws_s3_bucket_lifecycle_configuration" "app_logs" {
  bucket = aws_s3_bucket.app_logs.id

  rule {
    id     = "cleanup_old_logs"
    status = "Enabled"

    expiration {
      days = var.app_log_retention_days
    }
  }
}

# Database Backups Bucket
resource "aws_s3_bucket" "db_backups" {
  bucket = "${local.name_prefix}-db-backups"

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "db_backups" {
  bucket = aws_s3_bucket.db_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "db_backups" {
  bucket = aws_s3_bucket.db_backups.id

  rule {
    id     = "cleanup_old_backups"
    status = "Enabled"

    expiration {
      days = var.db_backup_retention_days
    }
  }
}

# KMS Key for S3 Bucket Encryption
resource "aws_kms_key" "s3" {
  count                   = var.kms_key_arn == "" ? 1 : 0
  description             = "KMS key for S3 bucket encryption"
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
        Sid    = "Allow S3 to use the key"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-s3-kms-key"
      Environment = var.environment
      Management  = "terraform"
    }
  )
}

resource "aws_kms_alias" "s3" {
  count         = var.kms_key_arn == "" ? 1 : 0
  name          = "alias/${var.environment}-s3-kms-key"
  target_key_id = aws_kms_key.s3[0].key_id
}

# Common bucket configurations
resource "aws_s3_bucket_server_side_encryption_configuration" "common" {
  for_each = {
    alb_logs      = aws_s3_bucket.alb_logs.id
    cloudtrail_logs = aws_s3_bucket.cloudtrail_logs.id
    config_logs   = aws_s3_bucket.config_logs.id
    app_logs      = aws_s3_bucket.app_logs.id
    db_backups    = aws_s3_bucket.db_backups.id
  }

  bucket = each.value

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn != "" ? var.kms_key_arn : aws_kms_key.s3[0].arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "common" {
  for_each = {
    alb_logs      = aws_s3_bucket.alb_logs.id
    cloudtrail_logs = aws_s3_bucket.cloudtrail_logs.id
    config_logs   = aws_s3_bucket.config_logs.id
    app_logs      = aws_s3_bucket.app_logs.id
    db_backups    = aws_s3_bucket.db_backups.id
  }

  bucket = each.value

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Common bucket configurations
resource "aws_s3_bucket_versioning" "common" {
  for_each = {
    alb_logs      = aws_s3_bucket.alb_logs.id
    cloudtrail_logs = aws_s3_bucket.cloudtrail_logs.id
    config_logs   = aws_s3_bucket.config_logs.id
    app_logs      = aws_s3_bucket.app_logs.id
    db_backups    = aws_s3_bucket.db_backups.id
  }

  bucket = each.value
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "common" {
  for_each = {
    alb_logs      = aws_s3_bucket.alb_logs.id
    cloudtrail_logs = aws_s3_bucket.cloudtrail_logs.id
    config_logs   = aws_s3_bucket.config_logs.id
    app_logs      = aws_s3_bucket.app_logs.id
    db_backups    = aws_s3_bucket.db_backups.id
  }

  bucket = each.value

  rule {
    id     = "cleanup_old_versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = var.alb_log_retention_days
    }
  }

  rule {
    id     = "delete_incomplete_multipart_uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
} 