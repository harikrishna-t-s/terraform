# Auto Scaling Group (ASG) Module

This Terraform module creates an Auto Scaling Group (ASG) with associated resources for a highly available and scalable application deployment on AWS.

## Features

- Launch template with user data for instance configuration
- Auto Scaling Group with health checks and instance refresh
- CloudWatch alarms for monitoring CPU, memory, and disk usage
- Automatic scaling policies based on metrics
- Integration with Application Load Balancer (ALB)
- Comprehensive logging and monitoring setup

## Usage

```hcl
module "asg" {
  source = "./modules/asg"

  environment           = "prod"
  vpc_id               = "vpc-12345678"
  private_subnet_ids   = ["subnet-1", "subnet-2"]
  app_security_group_id = "sg-12345678"
  instance_profile_name = "app-instance-profile"
  alb_target_group_arn  = "arn:aws:elasticloadbalancing:region:account:targetgroup/name/id"
  sns_topic_arn        = "arn:aws:sns:region:account:topic-name"

  # Optional parameters with defaults
  instance_type    = "t3.large"
  desired_capacity = 2
  min_size         = 1
  max_size         = 5
  app_port         = 8080

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
| vpc_id | ID of the VPC where the ASG will be deployed | `string` | n/a | yes |
| private_subnet_ids | List of private subnet IDs where EC2 instances will be launched | `list(string)` | n/a | yes |
| app_security_group_id | ID of the security group that controls access to the application instances | `string` | n/a | yes |
| instance_profile_name | Name of the IAM instance profile to attach to EC2 instances | `string` | n/a | yes |
| alb_target_group_arn | ARN of the ALB target group to register instances with | `string` | n/a | yes |
| ami_id | ID of the AMI to use for the EC2 instances | `string` | `"ami-0735c191cf914754d"` | no |
| instance_type | EC2 instance type for the application servers | `string` | `"t3.large"` | no |
| app_port | Port on which the application listens for incoming traffic | `number` | `8080` | no |
| desired_capacity | Desired number of instances in the Auto Scaling Group | `number` | `2` | no |
| min_size | Minimum number of instances in the Auto Scaling Group | `number` | `1` | no |
| max_size | Maximum number of instances in the Auto Scaling Group | `number` | `5` | no |
| sns_topic_arn | ARN of the SNS topic for CloudWatch alarm notifications | `string` | n/a | yes |
| tags | Additional tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| asg_name | Name of the Auto Scaling Group |
| asg_arn | ARN of the Auto Scaling Group |
| launch_template_id | ID of the launch template used by the Auto Scaling Group |
| launch_template_latest_version | Latest version number of the launch template |
| cloudwatch_alarm_ids | Map of CloudWatch alarm IDs for monitoring the Auto Scaling Group |
| scaling_policy_arns | Map of Auto Scaling policy ARNs for scaling the group |

## Monitoring

The module sets up the following CloudWatch alarms:
- High CPU utilization (>80%)
- Low CPU utilization (<20%)
- High memory utilization (>85%)
- High disk utilization (>85%)

## Scaling

The module implements the following scaling policies:
- Scale up: Increase capacity by 1 when CPU utilization is high
- Scale down: Decrease capacity by 1 when CPU utilization is low

## Security

- Instances are launched in private subnets
- Security groups control access to instances
- IAM instance profile provides least privilege access
- CloudWatch agent collects metrics and logs
- User data script configures secure defaults

## Troubleshooting

Common issues and solutions:

1. **Instances not launching**
   - Check VPC and subnet configurations
   - Verify security group rules
   - Review IAM instance profile permissions

2. **Scaling not working**
   - Verify CloudWatch alarm configurations
   - Check Auto Scaling Group metrics
   - Review scaling policy settings

3. **High CPU/Memory usage**
   - Review application performance
   - Check for resource leaks
   - Consider increasing instance size

## License

MIT Licensed. See LICENSE for full details. 