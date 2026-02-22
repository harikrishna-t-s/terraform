# Module Documentation Template

## Overview
Brief description of what this module does and its primary purpose.

## Resources Created
List of AWS resources this module creates:
- `aws_resource_name` - Description of the resource
- `aws_another_resource` - Description of the resource

## Usage Example
```hcl
module "module_name" {
  source = "./modules/module_name"
  
  # Required variables
  environment = "production"
  vpc_cidr    = "10.0.0.0/16"
  
  # Optional variables
  enable_dns_hostnames = true
  
  tags = {
    Project = "my-app"
    Owner   = "devops-team"
  }
}
```

## Requirements
| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 5.0 |

## Providers
| Name | Version |
|------|---------|
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| vpc_cidr | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| enable_dns_hostnames | Enable DNS hostnames in VPC | `bool` | `true` | no |
| tags | Additional tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| vpc_cidr_block | The CIDR block of the VPC |
| private_subnet_ids | List of private subnet IDs |
| public_subnet_ids | List of public subnet IDs |

## Security Considerations
- Security groups follow least privilege principle
- All resources are tagged for proper identification
- Encryption is enabled by default where applicable

## Notes
- This module requires appropriate IAM permissions
- Resource naming follows consistent convention
- Module supports multi-AZ deployments

## Authors
Maintained by your DevOps team

## License
MIT License
