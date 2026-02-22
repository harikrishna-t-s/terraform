# Data sources for dynamic values
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "main" {}
data "aws_vpc" "main" {
  id = var.vpc_id
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