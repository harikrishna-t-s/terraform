# Data sources for dynamic values
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_vpc" "main" {
  id = var.vpc_id
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get availability zones in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

# Get subnet information
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:Type"
    values = ["private"]
  }
}

# CloudWatch Agent IAM Role
resource "aws_iam_role" "cloudwatch_agent" {
  name = "${var.environment}-cloudwatch-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-cloudwatch-agent-role"
      Environment = var.environment
      Management  = "terraform"
    }
  )
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.cloudwatch_agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# CloudWatch Agent Configuration
data "template_file" "cloudwatch_agent_config" {
  template = file("${path.module}/templates/cloudwatch-agent-config.json")

  vars = {
    environment = var.environment
    log_group_name = "/aws/ec2/${var.environment}/application"
  }
}

# Launch Template
resource "aws_launch_template" "main" {
  name_prefix   = local.name_prefix
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [var.app_security_group_id]
    delete_on_termination      = true
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    environment = var.environment
    app_port    = var.app_port
    cloudwatch_agent_config = data.template_file.cloudwatch_agent_config.rendered
  }))

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.common_tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.common_tags
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "this" {
  name                = var.name
  desired_capacity    = var.scaling_config.desired_capacity
  max_size           = var.scaling_config.max_size
  min_size           = var.scaling_config.min_size
  target_group_arns  = var.target_group_arns
  vpc_zone_identifier = var.subnet_ids
  health_check_type   = var.scaling_config.health_check_type
  health_check_grace_period = var.scaling_config.health_check_grace_period

  launch_template {
    id      = var.launch_template_id
    version = var.launch_template_version
  }

  # Mixed Instances Policy
  dynamic "mixed_instances_policy" {
    for_each = var.scaling_config.mixed_instances_policy != null ? [1] : []
    content {
      instances_distribution {
        on_demand_percentage_above_base_capacity = var.scaling_config.mixed_instances_policy.on_demand_percentage_above_base_capacity
        spot_allocation_strategy                 = var.scaling_config.mixed_instances_policy.spot_allocation_strategy
        spot_instance_pools                      = var.scaling_config.mixed_instances_policy.spot_instance_pools
      }

      launch_template {
        launch_template_specification {
          launch_template_id   = var.launch_template_id
          version             = var.launch_template_version
        }

        dynamic "override" {
          for_each = var.scaling_config.mixed_instances_policy.instance_types
          content {
            instance_type     = override.value
            weighted_capacity = lookup(override.value, "weighted_capacity", null)
          }
        }
      }
    }
  }

  # Lifecycle Hooks
  dynamic "initial_lifecycle_hook" {
    for_each = var.scaling_config.lifecycle_hooks
    content {
      name                    = lifecycle_hook.value.name
      lifecycle_transition    = lifecycle_hook.value.lifecycle_transition
      default_result         = lifecycle_hook.value.default_result
      heartbeat_timeout      = lifecycle_hook.value.heartbeat_timeout
      notification_metadata  = lifecycle_hook.value.notification_metadata
      notification_target_arn = lifecycle_hook.value.notification_target_arn
      role_arn               = lifecycle_hook.value.role_arn
    }
  }

  # Target Tracking Policies
  dynamic "target_tracking_policy" {
    for_each = var.scaling_policies.target_tracking
    content {
      name               = "${var.name}-${target_tracking_policy.key}-target-tracking"
      policy_type        = "TargetTrackingScaling"
      target_tracking_configuration {
        predefined_metric_specification {
          predefined_metric_type = target_tracking_policy.value.predefined_metric_type
          resource_label        = lookup(target_tracking_policy.value, "resource_label", null)
        }
        target_value     = target_tracking_policy.value.target_value
        disable_scale_in = lookup(target_tracking_policy.value, "disable_scale_in", false)
      }
      estimated_instance_warmup = lookup(target_tracking_policy.value, "estimated_instance_warmup", 300)
    }
  }

  # Step Scaling Policies
  dynamic "step_scaling_policy" {
    for_each = var.scaling_policies.step_scaling
    content {
      name                   = "${var.name}-${step_scaling_policy.key}-step-scaling"
      policy_type           = "StepScaling"
      adjustment_type       = step_scaling_policy.value.adjustment_type
      cooldown             = step_scaling_policy.value.cooldown
      metric_aggregation_type = step_scaling_policy.value.metric_aggregation_type

      dynamic "step_adjustment" {
        for_each = step_scaling_policy.value.step_adjustments
        content {
          scaling_adjustment          = step_adjustment.value.scaling_adjustment
          metric_interval_lower_bound = lookup(step_adjustment.value, "metric_interval_lower_bound", null)
          metric_interval_upper_bound = lookup(step_adjustment.value, "metric_interval_upper_bound", null)
        }
      }
    }
  }

  # Scheduled Actions
  dynamic "scheduled_action" {
    for_each = var.scaling_config.scheduled_actions
    content {
      scheduled_action_name  = scheduled_action.value.name
      min_size              = lookup(scheduled_action.value, "min_size", null)
      max_size              = lookup(scheduled_action.value, "max_size", null)
      desired_capacity      = lookup(scheduled_action.value, "desired_capacity", null)
      start_time            = lookup(scheduled_action.value, "start_time", null)
      end_time              = lookup(scheduled_action.value, "end_time", null)
      recurrence            = lookup(scheduled_action.value, "recurrence", null)
      time_zone             = lookup(scheduled_action.value, "time_zone", null)
    }
  }

  tags = [
    for k, v in var.tags : {
      key                 = k
      value               = v
      propagate_at_launch = true
    }
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Policy - Scale Up
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${local.name_prefix}-scale-up"
  scaling_adjustment     = local.scaling_adjustments.scale_up
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.main.name
}

# Auto Scaling Policy - Scale Down
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${local.name_prefix}-scale-down"
  scaling_adjustment     = local.scaling_adjustments.scale_down
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.main.name
}

# CloudWatch Alarm - High CPU Utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${local.name_prefix}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period             = 300
  statistic          = "Average"
  threshold          = local.alarm_thresholds.cpu_high
  alarm_description  = "Scale up if CPU utilization is above ${local.alarm_thresholds.cpu_high}% for 10 minutes"
  alarm_actions      = [aws_autoscaling_policy.scale_up.arn, var.sns_topic_arn]
  ok_actions         = [var.sns_topic_arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
}

# CloudWatch Alarm - Low CPU Utilization
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${local.name_prefix}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period             = 300
  statistic          = "Average"
  threshold          = local.alarm_thresholds.cpu_low
  alarm_description  = "Scale down if CPU utilization is below ${local.alarm_thresholds.cpu_low}% for 10 minutes"
  alarm_actions      = [aws_autoscaling_policy.scale_down.arn, var.sns_topic_arn]
  ok_actions         = [var.sns_topic_arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
}

# CloudWatch Alarm - Memory Utilization
resource "aws_cloudwatch_metric_alarm" "memory_utilization" {
  alarm_name          = "${local.name_prefix}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "System/Linux"
  period             = 300
  statistic          = "Average"
  threshold          = local.alarm_thresholds.memory_high
  alarm_description  = "Alert if memory utilization is above ${local.alarm_thresholds.memory_high}% for 10 minutes"
  alarm_actions      = [var.sns_topic_arn]
  ok_actions         = [var.sns_topic_arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
}

# CloudWatch Alarm - Disk Space Utilization
resource "aws_cloudwatch_metric_alarm" "disk_utilization" {
  alarm_name          = "${local.name_prefix}-high-disk"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DiskSpaceUtilization"
  namespace           = "System/Linux"
  period             = 300
  statistic          = "Average"
  threshold          = local.alarm_thresholds.disk_high
  alarm_description  = "Alert if disk utilization is above ${local.alarm_thresholds.disk_high}% for 10 minutes"
  alarm_actions      = [var.sns_topic_arn]
  ok_actions         = [var.sns_topic_arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "asg" {
  dashboard_name = "${var.environment}-asg-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.main.name],
            ["System/Linux", "MemoryUtilization", "AutoScalingGroupName", aws_autoscaling_group.main.name]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "CPU and Memory Utilization"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["System/Linux", "DiskSpaceUtilization", "AutoScalingGroupName", aws_autoscaling_group.main.name],
            ["System/Linux", "SwapUtilization", "AutoScalingGroupName", aws_autoscaling_group.main.name]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Disk and Swap Utilization"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", aws_autoscaling_group.main.name],
            ["AWS/EC2", "NetworkOut", "AutoScalingGroupName", aws_autoscaling_group.main.name]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Network Traffic"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "StatusCheckFailed", "AutoScalingGroupName", aws_autoscaling_group.main.name],
            ["AWS/EC2", "StatusCheckFailed_Instance", "AutoScalingGroupName", aws_autoscaling_group.main.name],
            ["AWS/EC2", "StatusCheckFailed_System", "AutoScalingGroupName", aws_autoscaling_group.main.name]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Instance Status Checks"
        }
      }
    ]
  })
} 