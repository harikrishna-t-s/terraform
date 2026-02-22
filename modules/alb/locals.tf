locals {
  # Resource naming
  name_prefix = "alb-${var.environment}"

  # Common tags
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "alb"
    }
  )

  # ALB configuration
  alb_config = {
    name_prefix = local.name_prefix
    internal    = var.internal
    ip_address_type = "ipv4"
    load_balancer_type = "application"
  }

  # Target group configuration
  target_group_config = {
    name_prefix = "${local.name_prefix}-tg"
    port        = var.target_port
    protocol    = var.target_protocol
    vpc_id      = var.vpc_id
  }

  # Health check configuration
  health_check_config = {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    interval            = var.health_check_interval
    matcher            = var.health_check_matcher
    path               = var.health_check_path
    port               = var.health_check_port
    protocol           = var.health_check_protocol
    timeout            = var.health_check_timeout
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  # Stickiness configuration
  stickiness_config = {
    enabled          = var.stickiness_enabled
    cookie_duration  = var.stickiness_cookie_duration
    type            = "lb_cookie"
  }

  # S3 bucket configuration for ALB logs
  alb_logs_bucket_config = {
    name_prefix = "${local.name_prefix}-logs"
    force_destroy = true
  }

  # CloudWatch alarm thresholds
  alarm_thresholds = {
    http_5xx_errors     = var.http_5xx_error_threshold
    target_response_time = var.target_response_time_threshold
  }
} 