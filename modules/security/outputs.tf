output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = aws_guardduty_detector.main.id
}

output "config_recorder_name" {
  description = "Name of the AWS Config recorder"
  value       = aws_config_configuration_recorder.main.name
}

output "config_role_arn" {
  description = "ARN of the IAM role for AWS Config"
  value       = aws_iam_role.config.arn
}

output "securityhub_account_id" {
  description = "ID of the Security Hub account"
  value       = aws_securityhub_account.main.id
} 