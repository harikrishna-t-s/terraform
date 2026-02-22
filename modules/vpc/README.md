# VPC Module

This Terraform module creates a Virtual Private Cloud (VPC) with associated networking components for a highly available and secure infrastructure on AWS.

## Features

- VPC with configurable CIDR block
- Public, private, and database subnets across multiple availability zones
- Internet Gateway for public internet access
- NAT Gateways for private subnet internet access
- Route tables for subnet routing
- VPC Flow Logs for network traffic monitoring
- Comprehensive tagging strategy

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  environment = "prod"
  vpc_cidr    = "10.0.0.0/16"

  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  private_subnet_cidrs = [
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]

  database_subnet_cidrs = [
    "10.0.5.0/24",
    "10.0.6.0/24"
  ]

  availability_zones = [
    "us-west-2a",
    "us-west-2b"
  ]

  tags = {
    Project     = "MyApp"
    Environment = "production"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| vpc_cidr | CIDR block for the VPC | `string` | n/a | yes |
| public_subnet_cidrs | List of CIDR blocks for public subnets | `list(string)` | n/a | yes |
| private_subnet_cidrs | List of CIDR blocks for private subnets | `list(string)` | n/a | yes |
| database_subnet_cidrs | List of CIDR blocks for database subnets | `list(string)` | n/a | yes |
| availability_zones | List of availability zones to use | `list(string)` | n/a | yes |
| tags | Additional tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr_block | CIDR block of the VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| database_subnet_ids | List of database subnet IDs |
| public_route_table_id | ID of the public route table |
| private_route_table_ids | List of private route table IDs |
| database_route_table_id | ID of the database route table |
| nat_gateway_ids | List of NAT Gateway IDs |
| nat_gateway_public_ips | List of NAT Gateway public IPs |
| internet_gateway_id | ID of the Internet Gateway |
| vpc_flow_log_id | ID of the VPC Flow Log |
| vpc_flow_log_cloudwatch_log_group_arn | ARN of the CloudWatch Log Group for VPC Flow Logs |

## Network Architecture

The module creates the following network components:

1. **VPC**
   - Custom CIDR block
   - DNS hostnames and support enabled
   - VPC Flow Logs for network monitoring

2. **Subnets**
   - Public subnets with internet access
   - Private subnets with NAT Gateway access
   - Database subnets for RDS instances
   - All subnets distributed across multiple AZs

3. **Internet Connectivity**
   - Internet Gateway for public subnets
   - NAT Gateways for private subnets
   - Elastic IPs for NAT Gateways

4. **Routing**
   - Public route table with internet access
   - Private route tables with NAT Gateway access
   - Database route table for database subnets

5. **Monitoring**
   - VPC Flow Logs enabled
   - CloudWatch Log Group for flow logs
   - IAM role and policy for flow logs

## Security

- Private subnets for sensitive resources
- NAT Gateways for controlled internet access
- VPC Flow Logs for network monitoring
- Proper IAM roles and policies
- Comprehensive tagging for resource management

## Cost Considerations

- NAT Gateways incur hourly charges
- VPC Flow Logs may generate CloudWatch Logs charges
- Consider using NAT Instances for non-production environments

## Troubleshooting

Common issues and solutions:

1. **NAT Gateway Issues**
   - Verify Elastic IP allocation
   - Check route table configurations
   - Ensure proper security group rules

2. **VPC Flow Log Issues**
   - Verify IAM role permissions
   - Check CloudWatch Log Group configuration
   - Ensure proper IAM policy attachments

3. **Subnet Connectivity Issues**
   - Verify route table associations
   - Check security group rules
   - Validate network ACL configurations

## License

MIT Licensed. See LICENSE for full details. 