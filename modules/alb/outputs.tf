output "alb_id" {
  description = "The ID of the ALB"
  value       = aws_lb.alb.id
}

output "alb_arn" {
  description = "The ARN of the ALB"
  value       = aws_lb.alb.arn
}

output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.alb.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the ALB"
  value       = aws_lb.alb.zone_id
}

output "alb_security_group_id" {
  description = "The ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "target_group_arn" {
  description = "The ARN of the target group"
  value       = aws_lb_target_group.app.arn
}

output "target_group_name" {
  description = "The name of the target group"
  value       = aws_lb_target_group.app.name
}

output "listener_arns" {
  description = "A map of listener ARNs, keyed by protocol"
  value       = { for k, v in aws_lb_listener.main : k => v.arn }
}

output "listener_ids" {
  description = "A map of listener IDs, keyed by protocol"
  value       = { for k, v in aws_lb_listener.main : k => v.id }
}

output "listener_rule_arns" {
  description = "A map of listener rule ARNs, keyed by rule name"
  value       = { for k, v in aws_lb_listener_rule.main : k => v.arn }
}

output "listener_rule_ids" {
  description = "A map of listener rule IDs, keyed by rule name"
  value       = { for k, v in aws_lb_listener_rule.main : k => v.id }
}

output "cloudwatch_alarm_arns" {
  description = "A map of CloudWatch alarm ARNs"
  value = {
    http_5xx_errors     = aws_cloudwatch_metric_alarm.http_5xx_errors.arn
    target_response_time = aws_cloudwatch_metric_alarm.target_response_time.arn
  }
}

output "waf_web_acl_arn" {
  description = "The ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}

output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.id
}

output "cloudwatch_alarm_ids" {
  description = "IDs of the CloudWatch alarms for ALB"
  value = {
    alb_5xx_errors      = aws_cloudwatch_metric_alarm.alb_5xx_errors.id
    target_5xx_errors   = aws_cloudwatch_metric_alarm.alb_target_5xx_errors.id
    request_count       = aws_cloudwatch_metric_alarm.alb_request_count.id
  }
}

output "cloudwatch_dashboard_arn" {
  description = "The ARN of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.alb.arn
}

output "target_group_attachment_ids" {
  description = "A map of target group attachment IDs, keyed by target ID"
  value       = { for k, v in aws_lb_target_group_attachment.main : k => v.id }
}

output "target_group_attachment_arns" {
  description = "A map of target group attachment ARNs, keyed by target ID"
  value       = { for k, v in aws_lb_target_group_attachment.main : k => v.target_group_arn }
} 