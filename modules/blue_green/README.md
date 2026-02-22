# Blue/Green Deployment Module

This module implements a blue/green deployment strategy using AWS Auto Scaling Groups and Application Load Balancer.

## Features

- Blue/green deployment with Application Load Balancer
- Auto Scaling Groups with mixed instances policy support
- Target tracking scaling policies for dynamic scaling
- Comprehensive CloudWatch monitoring
- Configurable alarm thresholds and actions
- Health checks
- IAM roles and instance profiles
- Dynamic AMI lookup
- Lifecycle hooks for custom actions
- IMDSv2 support

## Usage

```hcl
module "blue_green" {
  source = "path/to/module"

  environment = "prod"
  region      = "us-west-2"

  vpc_id             = "vpc-12345678"
  subnet_ids         = ["subnet-12345678", "subnet-87654321"]
  security_group_ids = ["sg-12345678"]

  alb_listener_arn    = "arn:aws:elasticloadbalancing:us-west-2:123456789012:listener/app/my-alb/1234567890123456/1234567890123456"
  target_port         = 80
  health_check_path   = "/health"

  instance_config = {
    instance_type = "t3.micro"
    root_block_device = {
      volume_size = 20
      volume_type = "gp3"
      encrypted   = true
    }
    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = 1
      instance_metadata_tags      = "enabled"
    }
  }

  scaling_config = {
    min_size         = 1
    max_size         = 4
    desired_capacity = 2
    health_check_type = "ELB"
    health_check_grace_period = 300
    mixed_instances_policy = {
      on_demand_percentage_above_base_capacity = 25
      spot_allocation_strategy                 = "capacity-optimized"
      instance_types = ["t3.micro", "t3.small", "t3.medium"]
    }
  }

  scaling_policies = {
    target_tracking = {
      cpu_utilization = {
        target_value = 70.0
        disable_scale_in = false
      }
      memory_utilization = {
        target_value = 80.0
        disable_scale_in = false
      }
      request_count = {
        target_value = 1000
        disable_scale_in = false
      }
      custom_metric = {
        metric_name = "CustomMetric"
        namespace   = "CustomNamespace"
        statistic   = "Average"
        target_value = 50.0
        disable_scale_in = false
        dimensions = {
          "Environment" = "prod"
          "Service"     = "web"
        }
      }
    }
  }

  alarm_config = {
    cpu_utilization = {
      threshold = 80
      period    = 300
      actions = {
        alarm  = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
        ok     = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
      }
    }
    memory_utilization = {
      threshold = 85
      period    = 300
      actions = {
        alarm  = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
        ok     = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
      }
    }
    disk_utilization = {
      threshold = 80
      period    = 300
      actions = {
        alarm  = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
        ok     = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
      }
    }
    request_count = {
      threshold = 1000
      period    = 300
      actions = {
        alarm  = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
        ok     = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
      }
    }
    error_rate = {
      threshold = 5
      period    = 300
      actions = {
        alarm  = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
        ok     = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
      }
    }
    latency = {
      threshold = 1
      period    = 300
      actions = {
        alarm  = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
        ok     = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
      }
    }
  }

  tags = {
    Environment = "prod"
    Project     = "web-app"
    ManagedBy   = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name | `string` | n/a | yes |
| region | AWS region | `string` | n/a | yes |
| vpc_id | VPC ID | `string` | n/a | yes |
| subnet_ids | List of subnet IDs | `list(string)` | n/a | yes |
| security_group_ids | List of security group IDs | `list(string)` | n/a | yes |
| alb_listener_arn | ALB listener ARN | `string` | n/a | yes |
| target_port | Target port | `number` | n/a | yes |
| health_check_path | Health check path | `string` | n/a | yes |
| instance_config | Instance configuration | `object` | See below | no |
| scaling_config | Scaling configuration | `object` | See below | no |
| scaling_policies | Scaling policies | `object` | See below | no |
| alarm_config | Alarm configuration | `object` | See below | no |
| tags | Resource tags | `map(string)` | `{}` | no |

### Default Values

#### Instance Configuration
```hcl
{
  instance_type = "t3.micro"
  root_block_device = {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
}
```

#### Scaling Configuration
```hcl
{
  min_size         = 1
  max_size         = 4
  desired_capacity = 2
  health_check_type = "ELB"
  health_check_grace_period = 300
  mixed_instances_policy = {
    on_demand_percentage_above_base_capacity = 25
    spot_allocation_strategy                 = "capacity-optimized"
    instance_types = ["t3.micro", "t3.small", "t3.medium"]
  }
}
```

#### Scaling Policies
```hcl
{
  target_tracking = {
    cpu_utilization = {
      target_value = 70.0
      disable_scale_in = false
    }
    memory_utilization = {
      target_value = 80.0
      disable_scale_in = false
    }
    request_count = {
      target_value = 1000
      disable_scale_in = false
    }
    custom_metric = {
      metric_name = "CustomMetric"
      namespace   = "CustomNamespace"
      statistic   = "Average"
      target_value = 50.0
      disable_scale_in = false
      dimensions = {
        "Environment" = "prod"
        "Service"     = "web"
      }
    }
  }
}
```

#### Alarm Configuration
```hcl
{
  cpu_utilization = {
    threshold = 80
    period    = 300
    actions = {
      alarm  = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
      ok     = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
    }
  }
  memory_utilization = {
    threshold = 85
    period    = 300
    actions = {
      alarm  = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
      ok     = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
    }
  }
  disk_utilization = {
    threshold = 80
    period    = 300
    actions = {
      alarm  = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
      ok     = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
    }
  }
  request_count = {
    threshold = 1000
    period    = 300
    actions = {
      alarm  = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
      ok     = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
    }
  }
  error_rate = {
    threshold = 5
    period    = 300
    actions = {
      alarm  = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
      ok     = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
    }
  }
  latency = {
    threshold = 1
    period    = 300
    actions = {
      alarm  = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
      ok     = ["arn:aws:sns:us-west-2:123456789012:alarm-topic"]
    }
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| blue_asg_name | Name of the blue ASG |
| blue_asg_arn | ARN of the blue ASG |
| green_asg_name | Name of the green ASG |
| green_asg_arn | ARN of the green ASG |
| blue_target_group_arn | ARN of the blue target group |
| green_target_group_arn | ARN of the green target group |
| blue_iam_role_arn | ARN of the blue IAM role |
| green_iam_role_arn | ARN of the green IAM role |
| blue_iam_role_name | Name of the blue IAM role |
| green_iam_role_name | Name of the green IAM role |
| blue_instance_profile_arn | ARN of the blue instance profile |
| green_instance_profile_arn | ARN of the green instance profile |
| blue_instance_profile_name | Name of the blue instance profile |
| green_instance_profile_name | Name of the green instance profile |

## Monitoring

The module provides comprehensive monitoring through CloudWatch metrics and alarms:

### Metrics
- CPU Utilization
- Memory Utilization
- Disk Utilization
- Request Count
- Error Rate
- Latency

### Target Tracking Policies
- CPU Utilization Target Tracking
- Memory Utilization Target Tracking
- Request Count Target Tracking
- Custom Metric Target Tracking

### Alarms
- High CPU Utilization
- High Memory Utilization
- High Disk Utilization
- High Request Count
- High Error Rate
- High Latency

## Security

The module implements several security best practices:

- IAM roles with least privilege
- Security groups for network access control
- Encrypted EBS volumes
- IMDSv2 enforcement
- Secure metadata options
- Lifecycle hooks for secure instance termination

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This module is released under the MIT License. 