# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for ALB with granular access controls"
  vpc_id      = var.vpc_id

  # HTTP ingress from allowed CIDR blocks
  dynamic "ingress" {
    for_each = var.alb_ingress_cidr_blocks
    content {
      description = "HTTP ingress from ${ingress.key}"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # HTTPS ingress from allowed CIDR blocks
  dynamic "ingress" {
    for_each = var.alb_ingress_cidr_blocks
    content {
      description = "HTTPS ingress from ${ingress.key}"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # IPv6 HTTP ingress
  dynamic "ingress" {
    for_each = var.alb_ingress_ipv6_cidr_blocks
    content {
      description      = "HTTP ingress from IPv6"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      ipv6_cidr_blocks = [ingress.value]
    }
  }

  # IPv6 HTTPS ingress
  dynamic "ingress" {
    for_each = var.alb_ingress_ipv6_cidr_blocks
    content {
      description      = "HTTPS ingress from IPv6"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      ipv6_cidr_blocks = [ingress.value]
    }
  }

  # Health check ingress from VPC
  ingress {
    description = "Health check from VPC"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Egress to application servers
  egress {
    description     = "Outbound to application servers"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # Allow outbound internet access for ALB operations
  egress {
    description = "Outbound internet access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

# Application Security Group
resource "aws_security_group" "app" {
  name        = "${var.environment}-app-sg"
  description = "Security group for application servers with granular access controls"
  vpc_id      = var.vpc_id

  # Ingress from ALB
  ingress {
    description     = "Inbound from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # SSH access from bastion
  dynamic "ingress" {
    for_each = var.bastion_ingress_cidr_blocks
    content {
      description = "SSH from bastion"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # Egress to RDS
  egress {
    description     = "Outbound to RDS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.db.id]
  }

  # Egress to ElastiCache
  egress {
    description     = "Outbound to ElastiCache"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.elasticache.id]
  }

  # Egress to OpenSearch
  egress {
    description     = "Outbound to OpenSearch"
    from_port       = 9200
    to_port         = 9200
    protocol        = "tcp"
    security_groups = [aws_security_group.opensearch.id]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-app-sg"
      Environment = var.environment
      Management  = "terraform"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Database Security Group
resource "aws_security_group" "db" {
  name        = "${var.environment}-db-sg"
  description = "Security group for RDS with granular access controls"
  vpc_id      = var.vpc_id

  # Ingress from application servers
  ingress {
    description     = "Inbound from application servers"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # Maintenance access from bastion
  dynamic "ingress" {
    for_each = var.bastion_ingress_cidr_blocks
    content {
      description = "Maintenance access from bastion"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-db-sg"
      Environment = var.environment
      Management  = "terraform"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Bastion Security Group
resource "aws_security_group" "bastion" {
  name        = "${local.name_prefix}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from specified IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_ingress_cidr_blocks
  }

  egress {
    description     = "Allow all outbound traffic"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-bastion-sg"
    }
  )
}

# Redis Security Group
resource "aws_security_group" "redis" {
  name        = "${local.name_prefix}-redis-sg"
  description = "Security group for Redis cluster"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from application servers"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description     = "Allow all outbound traffic"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-redis-sg"
    }
  )
}

# Elasticsearch Security Group
resource "aws_security_group" "elasticsearch" {
  name        = "${local.name_prefix}-elasticsearch-sg"
  description = "Security group for Elasticsearch cluster"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Elasticsearch from application servers"
    from_port       = 9200
    to_port         = 9200
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  ingress {
    description     = "Elasticsearch transport from application servers"
    from_port       = 9300
    to_port         = 9300
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description     = "Allow all outbound traffic"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-elasticsearch-sg"
    }
  )
}

# VPC Endpoints Security Group
resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.name_prefix}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTPS from VPC"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = [var.vpc_cidr_block]
  }

  egress {
    description     = "Allow all outbound traffic"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-vpc-endpoints-sg"
    }
  )
}

# Network ACLs
resource "aws_network_acl" "public" {
  vpc_id = var.vpc_id

  # Allow inbound HTTP traffic
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Allow inbound HTTPS traffic
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow inbound ephemeral ports
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow all outbound traffic
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.naming.security_group}-public-nacl"
    }
  )
}

resource "aws_network_acl" "private" {
  vpc_id = var.vpc_id

  # Allow inbound traffic from public subnets
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 65535
  }

  # Allow all outbound traffic
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.naming.security_group}-private-nacl"
    }
  )
}

# ElastiCache Security Group
resource "aws_security_group" "elasticache" {
  name        = "${var.environment}-elasticache-sg"
  description = "Security group for ElastiCache with granular access controls"
  vpc_id      = var.vpc_id

  # Ingress from application servers
  ingress {
    description     = "Inbound from application servers"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-elasticache-sg"
      Environment = var.environment
      Management  = "terraform"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# OpenSearch Security Group
resource "aws_security_group" "opensearch" {
  name        = "${var.environment}-opensearch-sg"
  description = "Security group for OpenSearch with granular access controls"
  vpc_id      = var.vpc_id

  # Ingress from application servers
  ingress {
    description     = "Inbound from application servers"
    from_port       = 9200
    to_port         = 9200
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # Maintenance access from bastion
  dynamic "ingress" {
    for_each = var.bastion_ingress_cidr_blocks
    content {
      description = "Maintenance access from bastion"
      from_port   = 9200
      to_port     = 9200
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-opensearch-sg"
      Environment = var.environment
      Management  = "terraform"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
} 