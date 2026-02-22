output "blue_target_group_arn" {
  description = "ARN of the blue environment target group"
  value       = aws_lb_target_group.blue.arn
}

output "green_target_group_arn" {
  description = "ARN of the green environment target group"
  value       = aws_lb_target_group.green.arn
}

output "blue_asg_name" {
  description = "Name of the blue environment Auto Scaling Group"
  value       = aws_autoscaling_group.blue.name
}

output "green_asg_name" {
  description = "Name of the green environment Auto Scaling Group"
  value       = aws_autoscaling_group.green.name
}

output "blue_asg_arn" {
  description = "ARN of the blue environment Auto Scaling Group"
  value       = aws_autoscaling_group.blue.arn
}

output "green_asg_arn" {
  description = "ARN of the green environment Auto Scaling Group"
  value       = aws_autoscaling_group.green.arn
}

output "blue_scale_up_policy_arn" {
  description = "ARN of the blue environment scale up policy"
  value       = aws_autoscaling_policy.blue_scale_up.arn
}

output "blue_scale_down_policy_arn" {
  description = "ARN of the blue environment scale down policy"
  value       = aws_autoscaling_policy.blue_scale_down.arn
}

output "green_scale_up_policy_arn" {
  description = "ARN of the green environment scale up policy"
  value       = aws_autoscaling_policy.green_scale_up.arn
}

output "green_scale_down_policy_arn" {
  description = "ARN of the green environment scale down policy"
  value       = aws_autoscaling_policy.green_scale_down.arn
}

output "blue_iam_role_arn" {
  description = "ARN of the blue environment IAM role"
  value       = aws_iam_role.blue.arn
}

output "green_iam_role_arn" {
  description = "ARN of the green environment IAM role"
  value       = aws_iam_role.green.arn
}

output "blue_iam_instance_profile_arn" {
  description = "ARN of the blue environment IAM instance profile"
  value       = aws_iam_instance_profile.blue.arn
}

output "green_iam_instance_profile_arn" {
  description = "ARN of the green environment IAM instance profile"
  value       = aws_iam_instance_profile.green.arn
}

output "blue_launch_template_id" {
  description = "ID of the blue environment launch template"
  value       = aws_launch_template.blue.id
}

output "green_launch_template_id" {
  description = "ID of the green environment launch template"
  value       = aws_launch_template.green.id
}

output "asg_id" {
  description = "The ID of the Auto Scaling Group"
  value       = module.asg.asg_id
}

output "asg_name" {
  description = "The name of the Auto Scaling Group"
  value       = module.asg.asg_name
}

output "asg_arn" {
  description = "The ARN of the Auto Scaling Group"
  value       = module.asg.asg_arn
}

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = module.launch_template.launch_template_id
}

output "launch_template_name" {
  description = "The name of the launch template"
  value       = module.launch_template.launch_template_name
}

output "launch_template_latest_version" {
  description = "The latest version of the launch template"
  value       = module.launch_template.launch_template_latest_version
}

output "ami_id" {
  description = "The ID of the AMI used in the launch template"
  value       = module.launch_template.ami_id
}

output "alarm_arns" {
  description = "Map of all alarm ARNs"
  value       = module.alarms.alarm_arns
} 