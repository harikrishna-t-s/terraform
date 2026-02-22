output "launch_template_id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.this.id
}

output "launch_template_name" {
  description = "The name of the launch template"
  value       = aws_launch_template.this.name
}

output "launch_template_latest_version" {
  description = "The latest version of the launch template"
  value       = aws_launch_template.this.latest_version
}

output "ami_id" {
  description = "The ID of the AMI used in the launch template"
  value       = local.ami_id
} 