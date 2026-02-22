# Application Server IAM Role
resource "aws_iam_role" "app" {
  name = "${local.naming.iam_role}-app"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Application Server IAM Policy
resource "aws_iam_role_policy" "app" {
  name = "${local.naming.iam_role}-app-policy"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${local.naming.s3_bucket}-logs",
          "arn:aws:s3:::${local.naming.s3_bucket}-logs/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "arn:aws:kms:*:*:key/*"
        Condition = {
          StringEquals = {
            "kms:RequestAlias" = "alias/${local.naming.s3_bucket}-key"
          }
        }
      }
    ]
  })
}

# Application Server Instance Profile
resource "aws_iam_instance_profile" "app" {
  name = "${local.naming.iam_role}-app-profile"
  role = aws_iam_role.app.name

  tags = var.tags
}

# Database IAM Role
resource "aws_iam_role" "db" {
  name = "${local.naming.iam_role}-db"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Database IAM Policy
resource "aws_iam_role_policy" "db" {
  name = "${local.naming.iam_role}-db-policy"
  role = aws_iam_role.db.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${local.naming.s3_bucket}-backups",
          "arn:aws:s3:::${local.naming.s3_bucket}-backups/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "arn:aws:kms:*:*:key/*"
        Condition = {
          StringEquals = {
            "kms:RequestAlias" = "alias/${local.naming.s3_bucket}-key"
          }
        }
      }
    ]
  })
}

# Terraform Service Account IAM Role
resource "aws_iam_role" "terraform" {
  name = "${local.naming.iam_role}-terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:root"
        }
      }
    ]
  })

  tags = var.tags
}

# Terraform Service Account IAM Policy
resource "aws_iam_role_policy" "terraform" {
  name = "${local.naming.iam_role}-terraform-policy"
  role = aws_iam_role.terraform.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "rds:*",
          "s3:*",
          "iam:*",
          "cloudwatch:*",
          "logs:*",
          "kms:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "elasticache:*",
          "elasticsearch:*",
          "route53:*",
          "acm:*",
          "waf:*",
          "shield:*",
          "config:*",
          "cloudtrail:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# KMS Key for Encryption
resource "aws_kms_key" "main" {
  description             = "KMS key for ${local.name_prefix} encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${local.naming.s3_bucket}-key"
    }
  )
}

# KMS Alias
resource "aws_kms_alias" "main" {
  name          = "alias/${local.naming.s3_bucket}-key"
  target_key_id = aws_kms_key.main.key_id
}

# KMS Key Policy
resource "aws_kms_key_policy" "main" {
  key_id = aws_kms_key.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key"
        Effect = "Allow"
        Principal = {
          AWS = [
            aws_iam_role.app.arn,
            aws_iam_role.db.arn,
            aws_iam_role.terraform.arn
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow attachment of persistent resources"
        Effect = "Allow"
        Principal = {
          AWS = [
            aws_iam_role.app.arn,
            aws_iam_role.db.arn,
            aws_iam_role.terraform.arn
          ]
        }
        Action = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      }
    ]
  })
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2" {
  name = "${var.name_prefix}-ec2-role"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# CloudWatch Agent Policy
resource "aws_iam_policy" "cloudwatch_agent" {
  name        = "${var.name_prefix}-cloudwatch-agent-policy"
  description = "Policy for CloudWatch Agent"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# SSM Policy
resource "aws_iam_policy" "ssm" {
  name        = "${var.name_prefix}-ssm-policy"
  description = "Policy for Systems Manager"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# Attach policies to role
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.cloudwatch_agent.arn
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ssm.arn
}

# Attach AWS managed policies
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Role for RDS Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${local.name_prefix}-rds-monitoring-role"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Role for Lambda Functions
resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-lambda-role"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Role for ECS Tasks
resource "aws_iam_role" "ecs_task" {
  name = "${local.name_prefix}-ecs-task-role"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.name_prefix}-ecs-task-execution-role"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policies
resource "aws_iam_policy" "ec2_ssm" {
  name        = "${local.name_prefix}-ec2-ssm-policy"
  description = "Policy for EC2 instances to use Systems Manager"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "ec2_cloudwatch" {
  name        = "${local.name_prefix}-ec2-cloudwatch-policy"
  description = "Policy for EC2 instances to send logs to CloudWatch"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "lambda_basic" {
  name        = "${local.name_prefix}-lambda-basic-policy"
  description = "Basic policy for Lambda functions"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "ecs_task_execution" {
  name        = "${local.name_prefix}-ecs-task-execution-policy"
  description = "Policy for ECS task execution role"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# Policy Attachments
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ec2_ssm.arn
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ec2_cloudwatch.arn
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_basic.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_task_execution.arn
}

# RDS Monitoring Policy Attachment
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# AWS Secrets Manager Secret
resource "aws_secretsmanager_secret" "example" {
  name        = "${var.environment}-example-secret"
  description = "Example secret for demonstration"
  kms_key_id  = aws_kms_key.secrets.arn

  tags = local.common_tags
}

# KMS Key for Secrets Manager
resource "aws_kms_key" "secrets" {
  description             = "KMS key for encrypting secrets"
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
      }
    ]
  })

  tags = local.common_tags
}

# IAM Role for Secrets Manager
resource "aws_iam_role" "secrets_manager" {
  name = "${var.environment}-secrets-manager-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach AWS Managed Policy for Secrets Manager
resource "aws_iam_role_policy_attachment" "secrets_manager" {
  role       = aws_iam_role.secrets_manager.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

# Data source for IAM policy document
data "aws_iam_policy_document" "s3_access" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = var.allowed_ip_ranges
    }
  }
}

# Custom IAM Policy for S3 Access with Conditions
resource "aws_iam_policy" "s3_access" {
  name        = "${local.name_prefix}-s3-access-policy"
  description = "Policy for S3 access with conditions"
  policy      = data.aws_iam_policy_document.s3_access.json

  tags = local.common_tags
}

# IAM Role for S3 Access
resource "aws_iam_role" "s3_access" {
  name = "${local.name_prefix}-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId": var.external_id
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach AWS Managed Policy for S3 Access
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.s3_access.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# IAM Role for CloudWatch Logs
resource "aws_iam_role" "cloudwatch_logs" {
  name = "${local.name_prefix}-cloudwatch-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId": var.external_id
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach AWS Managed Policy for CloudWatch Logs
resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.cloudwatch_logs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonCloudWatchLogsFullAccess"
}

# KMS Key for S3 Encryption
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 encryption"
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

  tags = local.common_tags
}

# KMS Key for Secrets Manager
resource "aws_kms_key" "secrets" {
  description             = "KMS key for Secrets Manager"
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
      }
    ]
  })

  tags = local.common_tags
}

# Get current AWS account ID
data "aws_caller_identity" "current" {} 

locals {
  name_prefix = "${var.project}-${var.environment}"
  
  # Common tags
  common_tags = merge(
    var.common_tags,
    {
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "Terraform"
      Service     = "iam"
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
  tags               = local.common_tags
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
  tags               = local.common_tags
}

# IAM Policy for S3 KMS Access
data "aws_iam_policy_document" "s3_kms_access" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [var.s3_kms_key_arn]
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

resource "aws_iam_policy" "s3_kms_access" {
  name        = "${local.name_prefix}-s3-kms-access"
  description = "Policy for S3 to access KMS key"
  policy      = data.aws_iam_policy_document.s3_kms_access.json
  tags        = local.common_tags
}

resource "aws_iam_role_policy_attachment" "s3_kms_access" {
  role       = aws_iam_role.s3_access.name
  policy_arn = aws_iam_policy.s3_kms_access.arn
}

# IAM Policy for Secrets Manager KMS Access
data "aws_iam_policy_document" "secrets_kms_access" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]
    resources = [var.secrets_kms_key_arn]
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

resource "aws_iam_policy" "secrets_kms_access" {
  name        = "${local.name_prefix}-secrets-kms-access"
  description = "Policy for Secrets Manager to access KMS key"
  policy      = data.aws_iam_policy_document.secrets_kms_access.json
  tags        = local.common_tags
}

resource "aws_iam_role_policy_attachment" "secrets_kms_access" {
  role       = aws_iam_role.secrets_access.name
  policy_arn = aws_iam_policy.secrets_kms_access.arn
}

# IAM Roles with Least Privilege

# Application Role
resource "aws_iam_role" "app_role" {
  name = "${var.project}-${var.environment}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Application Policy with Least Privilege
resource "aws_iam_role_policy" "app_policy" {
  name = "${var.project}-${var.environment}-app-policy"
  role = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/${var.project}-${var.environment}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.project}-${var.environment}-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.app_logs_bucket_name}",
          "arn:aws:s3:::${var.app_logs_bucket_name}/*"
        ]
      }
    ]
  })
}

# Database Role
resource "aws_iam_role" "db_role" {
  name = "${var.project}-${var.environment}-db-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Database Policy with Least Privilege
resource "aws_iam_role_policy" "db_policy" {
  name = "${var.project}-${var.environment}-db-policy"
  role = aws_iam_role.db_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.db_backups_bucket_name}",
          "arn:aws:s3:::${var.db_backups_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [
          var.kms_key_arn
        ]
      }
    ]
  })
}

# Monitoring Role
resource "aws_iam_role" "monitoring_role" {
  name = "${var.project}-${var.environment}-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Monitoring Policy with Least Privilege
resource "aws_iam_role_policy" "monitoring_policy" {
  name = "${var.project}-${var.environment}-monitoring-policy"
  role = aws_iam_role.monitoring_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {} 