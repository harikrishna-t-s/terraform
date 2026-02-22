# Troubleshooting Guide

This guide provides solutions for common issues that may arise when using the Zero Trust Network Architecture module.

## Common Issues and Solutions

### Network Connectivity Issues

#### VPC Connectivity Problems
**Symptoms:**
- Instances cannot communicate
- NAT Gateway issues
- VPC endpoint failures
- Route table misconfigurations

**Solutions:**
1. Check VPC configuration:
```bash
aws ec2 describe-vpcs --vpc-ids ${vpc_id}
```

2. Verify route tables:
```bash
aws ec2 describe-route-tables --route-table-ids ${route_table_id}
```

3. Check NAT Gateway status:
```bash
aws ec2 describe-nat-gateways --nat-gateway-ids ${nat_gateway_id}
```

4. Update route table configuration:
```hcl
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = local.common_tags
}
```

#### Security Group Issues
**Symptoms:**
- Connection timeouts
- Access denied errors
- Unexpected traffic blocks
- Security group rule conflicts

**Solutions:**
1. Review security group rules:
```bash
aws ec2 describe-security-groups --group-ids ${security_group_id}
```

2. Check security group associations:
```bash
aws ec2 describe-network-interfaces --filters Name=group-id,Values=${security_group_id}
```

3. Update security group rules:
```hcl
resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "Security group for application servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}
```

### Network Firewall Issues

#### Firewall Rule Problems
**Symptoms:**
- Traffic blocked unexpectedly
- Rule conflicts
- Performance issues
- Policy violations

**Solutions:**
1. Check firewall policy:
```bash
aws network-firewall describe-firewall-policy --firewall-policy-arn ${policy_arn}
```

2. Review firewall rules:
```hcl
resource "aws_networkfirewall_firewall_policy" "main" {
  name = "${local.name_prefix}-firewall-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.main.arn
    }
  }

  tags = local.common_tags
}
```

3. Monitor firewall metrics:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/NetworkFirewall \
  --metric-name DroppedPackets \
  --dimensions Name=FirewallName,Value=${firewall_name} \
  --start-time $(date -u +"%Y-%m-%dT%H:%M:%SZ" -d "-1 hour") \
  --end-time $(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  --period 300 \
  --statistics Sum
```

#### VPC Endpoint Issues
**Symptoms:**
- Service access failures
- Endpoint timeouts
- Policy violations
- Connection errors

**Solutions:**
1. Check endpoint status:
```bash
aws ec2 describe-vpc-endpoints --vpc-endpoint-ids ${endpoint_id}
```

2. Verify endpoint policy:
```hcl
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${bucket_name}",
          "arn:aws:s3:::${bucket_name}/*"
        ]
      }
    ]
  })
}
```

### Monitoring and Logging Issues

#### Flow Log Problems
**Symptoms:**
- Missing flow logs
- Log delivery failures
- Storage issues
- Log format errors

**Solutions:**
1. Check flow log configuration:
```bash
aws ec2 describe-flow-logs --flow-log-ids ${flow_log_id}
```

2. Verify IAM roles:
```hcl
resource "aws_iam_role" "vpc_flow_log" {
  name = "${local.name_prefix}-vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}
```

3. Monitor CloudWatch metrics:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Logs \
  --metric-name ThrottledEvents \
  --dimensions Name=LogGroupName,Value=${log_group_name} \
  --start-time $(date -u +"%Y-%m-%dT%H:%M:%SZ" -d "-1 hour") \
  --end-time $(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  --period 300 \
  --statistics Sum
```

### Performance Issues

#### Network Latency
**Symptoms:**
- High latency
- Connection delays
- Timeout errors
- Bandwidth issues

**Solutions:**
1. Monitor network metrics:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name NetworkIn \
  --dimensions Name=InstanceId,Value=${instance_id} \
  --start-time $(date -u +"%Y-%m-%dT%H:%M:%SZ" -d "-1 hour") \
  --end-time $(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  --period 300 \
  --statistics Average
```

2. Optimize security group rules:
```hcl
resource "aws_security_group_rule" "app" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.app.id
}
```

3. Review NAT Gateway configuration:
```hcl
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = local.common_tags
}
```

## Best Practices

### Network Security
1. Use least privilege security groups
2. Implement network ACLs
3. Enable VPC Flow Logs
4. Use Network Firewall
5. Configure VPC endpoints

### Performance Optimization
1. Monitor network metrics
2. Optimize security group rules
3. Use appropriate instance types
4. Implement caching
5. Use connection pooling

### Cost Optimization
1. Monitor NAT Gateway usage
2. Review VPC endpoint costs
3. Optimize flow log retention
4. Use appropriate instance types
5. Implement auto-scaling

### Monitoring and Logging
1. Enable VPC Flow Logs
2. Configure CloudWatch alarms
3. Set up log retention
4. Monitor security metrics
5. Review access logs

## Getting Help

If you encounter issues not covered in this guide:

1. Check AWS documentation
2. Review CloudWatch logs
3. Enable VPC Flow Logs
4. Contact AWS support
5. Open a GitHub issue

## Contributing

To contribute to this troubleshooting guide:

1. Fork the repository
2. Create a feature branch
3. Add your solutions
4. Submit a pull request
5. Update documentation 