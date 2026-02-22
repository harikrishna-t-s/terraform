locals {
  # Resource naming
  name_prefix = var.name_prefix != "" ? var.name_prefix : "sg-${var.environment}"

  # Common tags
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "security_groups"
    }
  )

  # Security group rules configuration
  security_group_rules = {
    alb = {
      enable_http  = var.enable_alb_http
      enable_https = var.enable_alb_https
    }
    app = {
      enable_ssh = var.enable_app_ssh
    }
    db = {
      enable_postgres = var.enable_db_postgres
      enable_mysql    = var.enable_db_mysql
    }
  }

  # Service ports
  service_ports = {
    http        = 80
    https       = 443
    ssh         = 22
    postgres    = 5432
    mysql       = 3306
    redis       = 6379
    elasticsearch_http = 9200
    elasticsearch_transport = 9300
  }
} 