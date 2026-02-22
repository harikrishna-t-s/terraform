# Auto Scaling Group Information
output "asg_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}

output "asg_id" {
  description = "The ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.id
}

output "asg_arn" {
  description = "The ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.arn
}

output "asg_desired_capacity" {
  description = "The desired capacity of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.desired_capacity
}

output "asg_min_size" {
  description = "The minimum size of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.min_size
}

output "asg_max_size" {
  description = "The maximum size of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.max_size
}

output "asg_health_check_type" {
  description = "The health check type of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.health_check_type
}

output "asg_health_check_grace_period" {
  description = "The health check grace period of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.health_check_grace_period
}

output "asg_vpc_zone_identifier" {
  description = "The VPC zone identifier of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.vpc_zone_identifier
}

output "asg_target_group_arns" {
  description = "The target group ARNs of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.target_group_arns
}

# Launch Template Information
output "launch_template_id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.main.id
}

output "launch_template_latest_version" {
  description = "The latest version of the launch template"
  value       = aws_launch_template.main.latest_version
}

# Monitoring and Scaling Information
output "cloudwatch_alarm_ids" {
  description = "Map of CloudWatch alarm IDs for monitoring the Auto Scaling Group"
  value = {
    high_cpu           = aws_cloudwatch_metric_alarm.high_cpu.id
    low_cpu            = aws_cloudwatch_metric_alarm.low_cpu.id
    memory_utilization = aws_cloudwatch_metric_alarm.memory_utilization.id
    disk_utilization   = aws_cloudwatch_metric_alarm.disk_utilization.id
  }
}

output "scaling_policy_arns" {
  description = "Map of Auto Scaling policy ARNs for scaling the group"
  value = {
    scale_up   = aws_autoscaling_policy.scale_up.arn
    scale_down = aws_autoscaling_policy.scale_down.arn
  }
}

output "cloudwatch_agent_role_arn" {
  description = "The ARN of the IAM role for the CloudWatch agent"
  value       = aws_iam_role.cloudwatch_agent.arn
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group for application logs"
  value       = "/aws/ec2/${var.environment}/application"
}

output "cloudwatch_syslog_group_name" {
  description = "The name of the CloudWatch log group for system logs"
  value       = "/aws/ec2/${var.environment}/syslog"
} 