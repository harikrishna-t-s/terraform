# WAF Web ACL
resource "aws_wafv2_web_acl" "main" {
  name        = "${var.environment}-alb-waf"
  description = "WAF Web ACL for ALB"
  scope       = "REGIONAL"

  default_action {
    dynamic "allow" {
      for_each = var.waf_default_action == "allow" ? [1] : []
      content {}
    }
    dynamic "block" {
      for_each = var.waf_default_action == "block" ? [1] : []
      content {}
    }
  }

  dynamic "rule" {
    for_each = var.waf_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      dynamic "override_action" {
        for_each = rule.value.action == "none" ? [1] : []
        content {
          none {}
        }
      }

      dynamic "action" {
        for_each = rule.value.action != "none" ? [rule.value.action] : []
        content {
          dynamic "allow" {
            for_each = action.value == "allow" ? [1] : []
            content {}
          }
          dynamic "block" {
            for_each = action.value == "block" ? [1] : []
            content {}
          }
          dynamic "count" {
            for_each = action.value == "count" ? [1] : []
            content {}
          }
        }
      }

      statement {
        dynamic "managed_rule_group_statement" {
          for_each = rule.value.statement.managed_rule_group != null ? [rule.value.statement.managed_rule_group] : []
          content {
            name        = managed_rule_group_statement.value.name
            vendor_name = managed_rule_group_statement.value.vendor_name

            dynamic "excluded_rule" {
              for_each = managed_rule_group_statement.value.excluded_rules != null ? managed_rule_group_statement.value.excluded_rules : []
              content {
                name = excluded_rule.value
              }
            }
          }
        }

        dynamic "rate_based_statement" {
          for_each = rule.value.statement.rate_based != null ? [rule.value.statement.rate_based] : []
          content {
            limit              = rate_based_statement.value.limit
            aggregate_key_type = rate_based_statement.value.aggregate_key_type

            dynamic "scope_down_statement" {
              for_each = rate_based_statement.value.scope_down != null ? [rate_based_statement.value.scope_down] : []
              content {
                dynamic "ip_set_reference_statement" {
                  for_each = scope_down_statement.value.ip_set_reference_statement != null ? [scope_down_statement.value.ip_set_reference_statement] : []
                  content {
                    arn = ip_set_reference_statement.value.arn
                  }
                }
              }
            }
          }
        }

        dynamic "ip_set_reference_statement" {
          for_each = rule.value.statement.ip_set_reference != null ? [rule.value.statement.ip_set_reference] : []
          content {
            arn = ip_set_reference_statement.value.arn
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = rule.value.visibility_config.cloudwatch_metrics_enabled
        metric_name               = rule.value.visibility_config.metric_name
        sampled_requests_enabled  = rule.value.visibility_config.sampled_requests_enabled
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.waf_visibility_config.cloudwatch_metrics_enabled
    metric_name               = var.waf_visibility_config.metric_name
    sampled_requests_enabled  = var.waf_visibility_config.sampled_requests_enabled
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-alb-waf"
      Environment = var.environment
      Management  = "terraform"
    }
  )
}

# WAF Web ACL Association
resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
} 