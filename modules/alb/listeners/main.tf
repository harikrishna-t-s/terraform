# Target Group
resource "aws_lb_target_group" "app" {
  name        = "${var.environment}-app-tg"
  port        = var.target_port
  protocol    = var.target_protocol
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = var.health_check.enabled
    healthy_threshold   = var.health_check.healthy_threshold
    interval            = var.health_check.interval
    matcher            = var.health_check.matcher
    path               = var.health_check.path
    port               = var.health_check.port
    protocol           = var.health_check.protocol
    timeout            = var.health_check.timeout
    unhealthy_threshold = var.health_check.unhealthy_threshold
  }

  stickiness {
    enabled         = var.stickiness.enabled
    cookie_duration = var.stickiness.cookie_duration
    type           = var.stickiness.type
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-app-tg"
      Environment = var.environment
      Management  = "terraform"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "main" {
  for_each = var.target_group_attachments

  target_group_arn  = aws_lb_target_group.app.arn
  target_id         = each.value.target_id
  port              = coalesce(each.value.port, var.target_group_attachment_port, var.target_port)
  availability_zone = coalesce(each.value.availability_zone, var.target_group_attachment_availability_zone)

  lifecycle {
    create_before_destroy = true
  }
}

# Dynamic Listener Resource
resource "aws_lb_listener" "main" {
  for_each = var.listeners

  load_balancer_arn = var.alb_arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = each.value.protocol == "HTTPS" ? each.value.ssl_policy : null
  certificate_arn   = each.value.protocol == "HTTPS" ? each.value.certificate_arn : null

  dynamic "default_action" {
    for_each = [each.value.default_action]
    content {
      type = default_action.value.type

      dynamic "forward" {
        for_each = default_action.value.type == "forward" ? [default_action.value] : []
        content {
          target_group_arn = forward.value.target_group_arn != null ? forward.value.target_group_arn : aws_lb_target_group.app.arn
        }
      }

      dynamic "redirect" {
        for_each = default_action.value.type == "redirect" ? [default_action.value.redirect] : []
        content {
          port        = redirect.value.port
          protocol    = redirect.value.protocol
          status_code = redirect.value.status_code
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-alb-listener-${each.key}"
      Environment = var.environment
      Management  = "terraform"
    }
  )
}

# Dynamic Listener Rules
resource "aws_lb_listener_rule" "main" {
  for_each = var.listener_rules

  listener_arn = aws_lb_listener.main[each.value.listener_key].arn
  priority     = each.value.priority

  action {
    type             = each.value.action.type
    target_group_arn = each.value.action.type == "forward" ? (each.value.action.target_group_arn != null ? each.value.action.target_group_arn : aws_lb_target_group.app.arn) : null

    dynamic "fixed_response" {
      for_each = each.value.action.type == "fixed-response" ? [each.value.action.fixed_response] : []
      content {
        content_type = fixed_response.value.content_type
        message_body = fixed_response.value.message_body
        status_code  = fixed_response.value.status_code
      }
    }

    dynamic "redirect" {
      for_each = each.value.action.type == "redirect" ? [each.value.action.redirect] : []
      content {
        host        = redirect.value.host
        path        = redirect.value.path
        port        = redirect.value.port
        protocol    = redirect.value.protocol
        query       = redirect.value.query
        status_code = redirect.value.status_code
      }
    }
  }

  dynamic "condition" {
    for_each = [
      for condition in [
        each.value.condition.host_header != null ? {
          type  = "host-header"
          value = condition.host_header
        } : null,
        each.value.condition.path_pattern != null ? {
          type  = "path-pattern"
          value = condition.path_pattern
        } : null,
        each.value.condition.http_header != null ? {
          type  = "http-header"
          value = condition.http_header
        } : null,
        each.value.condition.http_request_method != null ? {
          type  = "http-request-method"
          value = condition.http_request_method
        } : null,
        each.value.condition.query_string != null ? {
          type  = "query-string"
          value = each.value.condition.query_string
        } : null,
        each.value.condition.source_ip != null ? {
          type  = "source-ip"
          value = condition.source_ip
        } : null
      ] : condition if condition != null
    ]
    content {
      dynamic "host_header" {
        for_each = condition.value.type == "host-header" ? [condition.value.value] : []
        content {
          values = host_header.value.values
        }
      }

      dynamic "path_pattern" {
        for_each = condition.value.type == "path-pattern" ? [condition.value.value] : []
        content {
          values = path_pattern.value.values
        }
      }

      dynamic "http_header" {
        for_each = condition.value.type == "http-header" ? [condition.value.value] : []
        content {
          http_header_name = http_header.value.http_header_name
          values          = http_header.value.values
        }
      }

      dynamic "http_request_method" {
        for_each = condition.value.type == "http-request-method" ? [condition.value.value] : []
        content {
          values = http_request_method.value.values
        }
      }

      dynamic "query_string" {
        for_each = condition.value.type == "query-string" ? [condition.value.value] : []
        content {
          key   = query_string.value.key
          value = query_string.value.value
        }
      }

      dynamic "source_ip" {
        for_each = condition.value.type == "source-ip" ? [condition.value.value] : []
        content {
          values = source_ip.value.values
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-alb-listener-rule-${each.key}"
      Environment = var.environment
      Management  = "terraform"
    }
  )
} 