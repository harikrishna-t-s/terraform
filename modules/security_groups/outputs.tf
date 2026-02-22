# ALB Security Group Outputs
output "alb_security_group_id" {
  description = "The ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "alb_security_group_name" {
  description = "Name of the ALB security group"
  value       = aws_security_group.alb.name
}

# Application Security Group Outputs
output "app_security_group_id" {
  description = "The ID of the application security group"
  value       = aws_security_group.app.id
}

output "app_security_group_name" {
  description = "Name of the application security group"
  value       = aws_security_group.app.name
}

# Database Security Group Outputs
output "db_security_group_id" {
  description = "The ID of the database security group"
  value       = aws_security_group.db.id
}

output "db_security_group_name" {
  description = "Name of the database security group"
  value       = aws_security_group.db.name
}

# Bastion Security Group Outputs
output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}

output "bastion_security_group_name" {
  description = "Name of the bastion security group"
  value       = aws_security_group.bastion.name
}

# Redis Security Group Outputs
output "redis_security_group_id" {
  description = "ID of the Redis security group"
  value       = var.enable_redis ? aws_security_group.redis[0].id : null
}

output "redis_security_group_name" {
  description = "Name of the Redis security group"
  value       = var.enable_redis ? aws_security_group.redis[0].name : null
}

# Elasticsearch Security Group Outputs
output "elasticsearch_security_group_id" {
  description = "ID of the Elasticsearch security group"
  value       = var.enable_elasticsearch ? aws_security_group.elasticsearch[0].id : null
}

output "elasticsearch_security_group_name" {
  description = "Name of the Elasticsearch security group"
  value       = var.enable_elasticsearch ? aws_security_group.elasticsearch[0].name : null
}

# VPC Endpoints Security Group Outputs
output "vpc_endpoints_security_group_id" {
  description = "ID of the VPC endpoints security group"
  value       = var.enable_vpc_endpoints ? aws_security_group.vpc_endpoints[0].id : null
}

output "vpc_endpoints_security_group_name" {
  description = "Name of the VPC endpoints security group"
  value       = var.enable_vpc_endpoints ? aws_security_group.vpc_endpoints[0].name : null
}

output "public_nacl_id" {
  description = "ID of the public network ACL"
  value       = aws_network_acl.public.id
}

output "private_nacl_id" {
  description = "ID of the private network ACL"
  value       = aws_network_acl.private.id
}

output "elasticache_security_group_id" {
  description = "The ID of the ElastiCache security group"
  value       = aws_security_group.elasticache.id
}

output "opensearch_security_group_id" {
  description = "The ID of the OpenSearch security group"
  value       = aws_security_group.opensearch.id
}

output "security_group_ids" {
  description = "Map of all security group IDs"
  value = {
    alb         = aws_security_group.alb.id
    app         = aws_security_group.app.id
    db          = aws_security_group.db.id
    elasticache = aws_security_group.elasticache.id
    opensearch  = aws_security_group.opensearch.id
  }
} 