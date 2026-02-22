output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "rds_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.database.rds_endpoint
  sensitive   = true
}

output "cloudtrail_bucket_name" {
  description = "Name of the S3 bucket storing CloudTrail logs"
  value       = module.s3.cloudtrail_bucket_name
}

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = module.security_groups.app_security_group_id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = module.security_groups.db_security_group_id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.security_groups.alb_security_group_id
}

output "app_instance_profile_name" {
  description = "Name of the IAM instance profile for application servers"
  value       = module.iam.app_instance_profile_name
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.cloudwatch.log_group_name
}

output "aws_config_recorder_name" {
  description = "Name of the AWS Config recorder"
  value       = module.aws_config.recorder_name
}

output "zero_trust_network" {
  description = "Outputs from the Zero Trust Network module"
  value = {
    vpc_id                = module.zero_trust_network.vpc_id
    vpc_cidr_block        = module.zero_trust_network.vpc_cidr_block
    private_subnet_ids    = module.zero_trust_network.private_subnet_ids
    public_subnet_ids     = module.zero_trust_network.public_subnet_ids
    private_route_table_ids = module.zero_trust_network.private_route_table_ids
    public_route_table_id = module.zero_trust_network.public_route_table_id
    nat_gateway_ids       = module.zero_trust_network.nat_gateway_ids
    network_firewall_id   = module.zero_trust_network.network_firewall_id
    vpc_endpoint_ids      = module.zero_trust_network.vpc_endpoint_ids
    security_group_ids    = module.zero_trust_network.security_group_ids
    flow_log_id           = module.zero_trust_network.flow_log_id
    kms_key_arn           = module.zero_trust_network.kms_key_arn
  }
}

output "security_automation" {
  description = "Outputs from the Security Automation module"
  value = {
    sns_topic_arn         = module.security_automation.sns_topic_arn
    sns_topic_name        = module.security_automation.sns_topic_name
    lambda_function_arn   = module.security_automation.lambda_function_arn
    lambda_function_name  = module.security_automation.lambda_function_name
    lambda_function_version = module.security_automation.lambda_function_version
    lambda_role_arn       = module.security_automation.lambda_role_arn
    eventbridge_rule_arn  = module.security_automation.eventbridge_rule_arn
    cloudwatch_alarm_arn  = module.security_automation.cloudwatch_alarm_arn
    kms_key_arn           = module.security_automation.kms_key_arn
    vpc_endpoint_logs_id  = module.security_automation.vpc_endpoint_logs_id
    security_group_lambda_id = module.security_automation.security_group_lambda_id
  }
}

output "threat_hunting" {
  description = "Outputs from the Threat Hunting module"
  value = {
    opensearch_domain_endpoint = module.threat_hunting.opensearch_domain_endpoint
    opensearch_domain_arn      = module.threat_hunting.opensearch_domain_arn
    opensearch_domain_id       = module.threat_hunting.opensearch_domain_id
    kibana_endpoint           = module.threat_hunting.kibana_endpoint
    lambda_function_arn       = module.threat_hunting.lambda_function_arn
    lambda_function_name      = module.threat_hunting.lambda_function_name
    lambda_function_version   = module.threat_hunting.lambda_function_version
    lambda_role_arn           = module.threat_hunting.lambda_role_arn
    sns_topic_arn             = module.threat_hunting.sns_topic_arn
    eventbridge_rule_arn      = module.threat_hunting.eventbridge_rule_arn
    cloudwatch_alarm_arn      = module.threat_hunting.cloudwatch_alarm_arn
    kms_key_arn               = module.threat_hunting.kms_key_arn
    vpc_endpoint_ids          = module.threat_hunting.vpc_endpoint_ids
    security_group_ids        = module.threat_hunting.security_group_ids
    cloudwatch_log_group_arns = module.threat_hunting.cloudwatch_log_group_arns
  }
} 