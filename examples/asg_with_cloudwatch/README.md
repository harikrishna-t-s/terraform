# Auto Scaling Group with CloudWatch Agent Example

This example demonstrates how to use the CloudWatch agent module with an Auto Scaling Group to collect metrics and logs from EC2 instances.

## Features

- VPC setup with public and private subnets
- Auto Scaling Group with Launch Template
- CloudWatch agent integration
- Security group configuration
- Custom metrics and logs collection

## Usage

1. Initialize Terraform:
```bash
terraform init
```

2. Review the execution plan:
```bash
terraform plan
```

3. Apply the configuration:
```bash
terraform apply
```

## Configuration

The example includes:

- A VPC with public and private subnets
- An Auto Scaling Group with a Launch Template
- CloudWatch agent configuration for metrics and logs
- Security group for instance access
- IAM roles and policies for CloudWatch agent

## Customization

You can customize the example by modifying the variables in `variables.tf`:

- `environment`: Environment name
- `region`: AWS region
- `instance_type`: EC2 instance type
- `desired_capacity`: Desired number of instances
- `max_size`: Maximum number of instances
- `min_size`: Minimum number of instances

## Monitoring

The CloudWatch agent is configured to collect:

- System metrics (CPU, memory, disk)
- Application logs
- Custom metrics as specified in the configuration

You can view the collected metrics and logs in the AWS CloudWatch console.

## Cleanup

To destroy the resources:

```bash
terraform destroy
``` 