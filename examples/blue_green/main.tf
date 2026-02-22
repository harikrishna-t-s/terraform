module "blue_green" {
  source = "../../modules/blue_green"

  environment = "prod"
  region      = "us-west-2"

  vpc_id             = "vpc-12345678"
  subnet_ids         = ["subnet-12345678", "subnet-87654321"]
  security_group_ids = ["sg-12345678"]

  alb_listener_arn = "arn:aws:elasticloadbalancing:us-west-2:123456789012:listener/app/my-alb/1234567890123456/1234567890123456"
  target_port      = 80
  health_check_path = "/health"

  instance_config = {
    type = "t3.micro"
    root_block_device = {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = 1
      instance_metadata_tags      = "enabled"
    }
  }

  scaling_config = {
    min_size                = 1
    max_size                = 4
    desired_capacity        = 2
    health_check_type       = "ELB"
    health_check_grace_period = 300
    default_cooldown        = 300
    termination_policies    = ["OldestInstance"]
    protect_from_scale_in   = false
    capacity_rebalance      = true
    mixed_instances_policy = {
      instances_distribution = {
        on_demand_percentage_above_base_capacity = 25
        spot_allocation_strategy                 = "capacity-optimized"
        spot_instance_pools                      = 2
      }
      override = [
        {
          instance_type     = "t3.micro"
          weighted_capacity = 1
        },
        {
          instance_type     = "t3.small"
          weighted_capacity = 2
        }
      ]
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