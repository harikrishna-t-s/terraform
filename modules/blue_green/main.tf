# Blue/Green Deployment Module
# This module implements blue/green deployment strategy using ASG and ALB

# AMI Data Source
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

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Centralized Naming and Configuration
locals {
  # Resource Name Prefixes
  name_prefix = {
    blue = "${var.environment}-blue"
    green = "${var.environment}-green"
  }

  # Resource Names
  resource_names = {
    asg = {
      blue = "${local.name_prefix.blue}-asg"
      green = "${local.name_prefix.green}-asg"
    }
    target_group = {
      blue = "${local.name_prefix.blue}-tg"
      green = "${local.name_prefix.green}-tg"
    }
    launch_template = {
      blue = "${local.name_prefix.blue}-lt"
      green = "${local.name_prefix.green}-lt"
    }
    iam_role = {
      blue = "${local.name_prefix.blue}-instance-role"
      green = "${local.name_prefix.green}-instance-role"
    }
    iam_policy = {
      blue = "${local.name_prefix.blue}-instance-policy"
      green = "${local.name_prefix.green}-instance-policy"
    }
    iam_profile = {
      blue = "${local.name_prefix.blue}-instance-profile"
      green = "${local.name_prefix.green}-instance-profile"
    }
  }

  # Scaling Adjustments
  scaling_adjustments = {
    scale_up = 1
    scale_down = -1
  }

  # Alarm Names
  alarm_names = {
    cpu_utilization = {
      high = "${var.alarm_name_prefix}${var.environment}-%s-cpu-utilization-high"
      low = "${var.alarm_name_prefix}${var.environment}-%s-cpu-utilization-low"
    }
    memory_utilization = {
      high = "${var.alarm_name_prefix}${var.environment}-%s-memory-utilization-high"
      low = "${var.alarm_name_prefix}${var.environment}-%s-memory-utilization-low"
    }
    disk_utilization = {
      high = "${var.alarm_name_prefix}${var.environment}-%s-disk-utilization-high"
      low = "${var.alarm_name_prefix}${var.environment}-%s-disk-utilization-low"
    }
    request_count = {
      high = "${var.alarm_name_prefix}${var.environment}-%s-request-count-high"
      low = "${var.alarm_name_prefix}${var.environment}-%s-request-count-low"
    }
    error_rate = {
      high = "${var.alarm_name_prefix}${var.environment}-%s-error-rate-high"
      low = "${var.alarm_name_prefix}${var.environment}-%s-error-rate-low"
    }
    latency = {
      high = "${var.alarm_name_prefix}${var.environment}-%s-latency-high"
      low = "${var.alarm_name_prefix}${var.environment}-%s-latency-low"
    }
  }

  # Common tags that should be applied to all resources
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "blue-green-deployment"
    }
  )

  # Blue environment specific tags
  blue_tags = merge(
    local.common_tags,
    {
      Type = "blue"
    }
  )

  # Green environment specific tags
  green_tags = merge(
    local.common_tags,
    {
      Type = "green"
    }
  )

  # ASG specific tags that need to be propagated to instances
  asg_tags = {
    Name = {
      blue  = "${var.environment}-blue-instance"
      green = "${var.environment}-green-instance"
    }
    Environment = {
      blue  = var.environment
      green = var.environment
    }
    Type = {
      blue  = "blue"
      green = "green"
    }
  }

  # Use provided AMI ID or fall back to latest Amazon Linux 2 AMI
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux_2.id
}

# ALB Target Group for Blue Environment
resource "aws_lb_target_group" "blue" {
  name        = local.resource_names.target_group.blue
  port        = var.target_port
  protocol    = var.target_protocol
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    interval            = var.health_check_interval
    matcher            = var.health_check_matcher
    path               = var.health_check_path
    port               = var.health_check_port
    protocol           = var.health_check_protocol
    timeout            = var.health_check_timeout
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = local.blue_tags
}

# ALB Target Group for Green Environment
resource "aws_lb_target_group" "green" {
  name        = local.resource_names.target_group.green
  port        = var.target_port
  protocol    = var.target_protocol
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    interval            = var.health_check_interval
    matcher            = var.health_check_matcher
    path               = var.health_check_path
    port               = var.health_check_port
    protocol           = var.health_check_protocol
    timeout            = var.health_check_timeout
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = local.green_tags
}

# ALB Listener Rule for Blue Environment
resource "aws_lb_listener_rule" "blue" {
  listener_arn = var.alb_listener_arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  condition {
    path_pattern {
      values = var.blue_path_patterns
    }
  }

  tags = local.blue_tags
}

# ALB Listener Rule for Green Environment
resource "aws_lb_listener_rule" "green" {
  listener_arn = var.alb_listener_arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }

  condition {
    path_pattern {
      values = var.green_path_patterns
    }
  }

  tags = local.green_tags
}

# Launch Template for Blue Environment
resource "aws_launch_template" "blue" {
  name_prefix   = "${local.resource_names.launch_template.blue}-"
  image_id      = local.ami_id
  instance_type = var.instance_config.type

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = var.security_group_ids
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.blue.name
  }

  # Enhanced block device mappings
  dynamic "block_device_mappings" {
    for_each = var.instance_config.block_device_mappings
    content {
      device_name = block_device_mappings.value.device_name

      ebs {
        volume_size           = block_device_mappings.value.ebs.volume_size
        volume_type           = block_device_mappings.value.ebs.volume_type
        iops                  = lookup(block_device_mappings.value.ebs, "iops", null)
        throughput            = lookup(block_device_mappings.value.ebs, "throughput", null)
        encrypted             = block_device_mappings.value.ebs.encrypted
        kms_key_id            = lookup(block_device_mappings.value.ebs, "kms_key_id", null)
        delete_on_termination = block_device_mappings.value.ebs.delete_on_termination
        snapshot_id           = lookup(block_device_mappings.value.ebs, "snapshot_id", null)
      }

      no_device    = lookup(block_device_mappings.value, "no_device", null)
      virtual_name = lookup(block_device_mappings.value, "virtual_name", null)
    }
  }

  metadata_options {
    http_endpoint               = var.instance_config.metadata_options.http_endpoint
    http_tokens                 = var.instance_config.metadata_options.http_tokens
    http_put_response_hop_limit = var.instance_config.metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = var.instance_config.metadata_options.instance_metadata_tags
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    environment = var.environment
    region      = var.region
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = local.blue_tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.blue_tags
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = local.blue_tags
}

# Launch Template for Green Environment
resource "aws_launch_template" "green" {
  name_prefix   = "${local.resource_names.launch_template.green}-"
  image_id      = local.ami_id
  instance_type = var.instance_config.type

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = var.security_group_ids
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.green.name
  }

  # Enhanced block device mappings
  dynamic "block_device_mappings" {
    for_each = var.instance_config.block_device_mappings
    content {
      device_name = block_device_mappings.value.device_name

      ebs {
        volume_size           = block_device_mappings.value.ebs.volume_size
        volume_type           = block_device_mappings.value.ebs.volume_type
        iops                  = lookup(block_device_mappings.value.ebs, "iops", null)
        throughput            = lookup(block_device_mappings.value.ebs, "throughput", null)
        encrypted             = block_device_mappings.value.ebs.encrypted
        kms_key_id            = lookup(block_device_mappings.value.ebs, "kms_key_id", null)
        delete_on_termination = block_device_mappings.value.ebs.delete_on_termination
        snapshot_id           = lookup(block_device_mappings.value.ebs, "snapshot_id", null)
      }

      no_device    = lookup(block_device_mappings.value, "no_device", null)
      virtual_name = lookup(block_device_mappings.value, "virtual_name", null)
    }
  }

  metadata_options {
    http_endpoint               = var.instance_config.metadata_options.http_endpoint
    http_tokens                 = var.instance_config.metadata_options.http_tokens
    http_put_response_hop_limit = var.instance_config.metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = var.instance_config.metadata_options.instance_metadata_tags
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    environment = var.environment
    region      = var.region
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = local.green_tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.green_tags
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = local.green_tags
}

# Auto Scaling Group for Blue Environment
resource "aws_autoscaling_group" "blue" {
  name                = local.resource_names.asg.blue
  vpc_zone_identifier = var.subnet_ids
  desired_capacity    = var.scaling_config.desired_capacity
  max_size           = var.scaling_config.max_size
  min_size           = var.scaling_config.min_size

  launch_template {
    id      = aws_launch_template.blue.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.blue.arn]

  health_check_type         = var.scaling_config.health_check_type
  health_check_grace_period = var.scaling_config.health_check_grace_period
  default_cooldown         = var.scaling_config.default_cooldown
  termination_policies     = var.scaling_config.termination_policies
  protect_from_scale_in    = var.scaling_config.protect_from_scale_in
  capacity_rebalance       = var.scaling_config.capacity_rebalance

  dynamic "mixed_instances_policy" {
    for_each = var.scaling_config.mixed_instances_policy != null ? [1] : []
    content {
      instances_distribution {
        on_demand_percentage_above_base_capacity = var.scaling_config.mixed_instances_policy.instances_distribution.on_demand_percentage_above_base_capacity
        spot_allocation_strategy                 = var.scaling_config.mixed_instances_policy.instances_distribution.spot_allocation_strategy
        spot_instance_pools                      = var.scaling_config.mixed_instances_policy.instances_distribution.spot_instance_pools
      }

      launch_template {
        launch_template_specification {
          launch_template_id = aws_launch_template.blue.id
          version           = "$Latest"
        }

        dynamic "override" {
          for_each = var.scaling_config.mixed_instances_policy.override
          content {
            instance_type     = override.value.instance_type
            weighted_capacity = override.value.weighted_capacity
          }
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  # Convert the ASG tags map to the required format
  dynamic "tag" {
    for_each = merge(
      local.asg_tags,
      {
        for k, v in local.blue_tags : k => {
          blue  = v
          green = v
        }
      }
    )
    content {
      key                 = tag.key
      value               = tag.value.blue
      propagate_at_launch = true
    }
  }
}

# Auto Scaling Group for Green Environment
resource "aws_autoscaling_group" "green" {
  name                = local.resource_names.asg.green
  vpc_zone_identifier = var.subnet_ids
  desired_capacity    = var.scaling_config.desired_capacity
  max_size           = var.scaling_config.max_size
  min_size           = var.scaling_config.min_size

  launch_template {
    id      = aws_launch_template.green.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.green.arn]

  health_check_type         = var.scaling_config.health_check_type
  health_check_grace_period = var.scaling_config.health_check_grace_period
  default_cooldown         = var.scaling_config.default_cooldown
  termination_policies     = var.scaling_config.termination_policies
  protect_from_scale_in    = var.scaling_config.protect_from_scale_in
  capacity_rebalance       = var.scaling_config.capacity_rebalance

  dynamic "mixed_instances_policy" {
    for_each = var.scaling_config.mixed_instances_policy != null ? [1] : []
    content {
      instances_distribution {
        on_demand_percentage_above_base_capacity = var.scaling_config.mixed_instances_policy.instances_distribution.on_demand_percentage_above_base_capacity
        spot_allocation_strategy                 = var.scaling_config.mixed_instances_policy.instances_distribution.spot_allocation_strategy
        spot_instance_pools                      = var.scaling_config.mixed_instances_policy.instances_distribution.spot_instance_pools
      }

      launch_template {
        launch_template_specification {
          launch_template_id = aws_launch_template.green.id
          version           = "$Latest"
        }

        dynamic "override" {
          for_each = var.scaling_config.mixed_instances_policy.override
          content {
            instance_type     = override.value.instance_type
            weighted_capacity = override.value.weighted_capacity
          }
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  # Convert the ASG tags map to the required format
  dynamic "tag" {
    for_each = merge(
      local.asg_tags,
      {
        for k, v in local.green_tags : k => {
          blue  = v
          green = v
        }
      }
    )
    content {
      key                 = tag.key
      value               = tag.value.green
      propagate_at_launch = true
    }
  }
}

# CloudWatch Alarms for Blue Environment
resource "aws_cloudwatch_metric_alarm" "blue_cpu_high" {
  count               = var.enable_alarms.cpu_utilization ? 1 : 0
  alarm_name          = format(local.alarm_names.cpu_utilization.high, "blue")
  comparison_operator = var.alarm_config.cpu_utilization.comparison_operator
  evaluation_periods  = var.alarm_config.cpu_utilization.evaluation_periods
  datapoints_to_alarm = var.alarm_config.cpu_utilization.datapoints_to_alarm
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period             = var.alarm_config.cpu_utilization.period
  statistic          = var.alarm_config.cpu_utilization.statistic
  threshold          = var.alarm_config.cpu_utilization.high_threshold
  treat_missing_data = var.alarm_config.cpu_utilization.treat_missing_data
  alarm_description  = "${var.alarm_description_prefix} EC2 CPU utilization for blue environment"
  alarm_actions      = concat(var.alarm_actions.alarm_actions, [aws_autoscaling_policy.blue_scale_up.arn])
  ok_actions         = var.alarm_actions.ok_actions
  insufficient_data_actions = var.alarm_actions.insufficient_data_actions

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.blue.name
  }

  tags = merge(
    local.blue_tags,
    var.alarm_tags,
    {
      Metric = "CPUUtilization"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "blue_cpu_low" {
  count               = var.enable_alarms.cpu_utilization ? 1 : 0
  alarm_name          = format(local.alarm_names.cpu_utilization.low, "blue")
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.alarm_config.cpu_utilization.evaluation_periods
  datapoints_to_alarm = var.alarm_config.cpu_utilization.datapoints_to_alarm
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period             = var.alarm_config.cpu_utilization.period
  statistic          = var.alarm_config.cpu_utilization.statistic
  threshold          = var.alarm_config.cpu_utilization.low_threshold
  treat_missing_data = var.alarm_config.cpu_utilization.treat_missing_data
  alarm_description  = "${var.alarm_description_prefix} EC2 CPU utilization for blue environment"
  alarm_actions      = concat(var.alarm_actions.alarm_actions, [aws_autoscaling_policy.blue_scale_down.arn])
  ok_actions         = var.alarm_actions.ok_actions
  insufficient_data_actions = var.alarm_actions.insufficient_data_actions

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.blue.name
  }

  tags = merge(
    local.blue_tags,
    var.alarm_tags,
    {
      Metric = "CPUUtilization"
    }
  )
}

# Memory Utilization Alarms for Blue Environment
resource "aws_cloudwatch_metric_alarm" "blue_memory_high" {
  count               = var.enable_alarms.memory_utilization ? 1 : 0
  alarm_name          = format(local.alarm_names.memory_utilization.high, "blue")
  comparison_operator = var.alarm_config.memory_utilization.comparison_operator
  evaluation_periods  = var.alarm_config.memory_utilization.evaluation_periods
  datapoints_to_alarm = var.alarm_config.memory_utilization.datapoints_to_alarm
  metric_name         = "MemoryUtilization"
  namespace           = "System/Linux"
  period             = var.alarm_config.memory_utilization.period
  statistic          = var.alarm_config.memory_utilization.statistic
  threshold          = var.alarm_config.memory_utilization.high_threshold
  treat_missing_data = var.alarm_config.memory_utilization.treat_missing_data
  alarm_description  = "${var.alarm_description_prefix} memory utilization for blue environment"
  alarm_actions      = var.alarm_actions.alarm_actions
  ok_actions         = var.alarm_actions.ok_actions
  insufficient_data_actions = var.alarm_actions.insufficient_data_actions

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.blue.name
  }

  tags = merge(
    local.blue_tags,
    var.alarm_tags,
    {
      Metric = "MemoryUtilization"
    }
  )
}

# Disk Utilization Alarms for Blue Environment
resource "aws_cloudwatch_metric_alarm" "blue_disk_high" {
  count               = var.enable_alarms.disk_utilization ? 1 : 0
  alarm_name          = format(local.alarm_names.disk_utilization.high, "blue")
  comparison_operator = var.alarm_config.disk_utilization.comparison_operator
  evaluation_periods  = var.alarm_config.disk_utilization.evaluation_periods
  datapoints_to_alarm = var.alarm_config.disk_utilization.datapoints_to_alarm
  metric_name         = "DiskSpaceUtilization"
  namespace           = "System/Linux"
  period             = var.alarm_config.disk_utilization.period
  statistic          = var.alarm_config.disk_utilization.statistic
  threshold          = var.alarm_config.disk_utilization.high_threshold
  treat_missing_data = var.alarm_config.disk_utilization.treat_missing_data
  alarm_description  = "${var.alarm_description_prefix} disk space utilization for blue environment"
  alarm_actions      = var.alarm_actions.alarm_actions
  ok_actions         = var.alarm_actions.ok_actions
  insufficient_data_actions = var.alarm_actions.insufficient_data_actions

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.blue.name
  }

  tags = merge(
    local.blue_tags,
    var.alarm_tags,
    {
      Metric = "DiskSpaceUtilization"
    }
  )
}

# Request Count Alarms for Blue Environment
resource "aws_cloudwatch_metric_alarm" "blue_request_count_high" {
  count               = var.enable_alarms.request_count ? 1 : 0
  alarm_name          = format(local.alarm_names.request_count.high, "blue")
  comparison_operator = var.alarm_config.request_count.comparison_operator
  evaluation_periods  = var.alarm_config.request_count.evaluation_periods
  datapoints_to_alarm = var.alarm_config.request_count.datapoints_to_alarm
  metric_name         = "RequestCount"
  namespace           = "AWS/ApplicationELB"
  period             = var.alarm_config.request_count.period
  statistic          = var.alarm_config.request_count.statistic
  threshold          = var.alarm_config.request_count.high_threshold
  treat_missing_data = var.alarm_config.request_count.treat_missing_data
  alarm_description  = "${var.alarm_description_prefix} request count for blue environment"
  alarm_actions      = var.alarm_actions.alarm_actions
  ok_actions         = var.alarm_actions.ok_actions
  insufficient_data_actions = var.alarm_actions.insufficient_data_actions

  dimensions = {
    TargetGroup  = aws_lb_target_group.blue.arn_suffix
    LoadBalancer = split("/", var.alb_listener_arn)[1]
  }

  tags = merge(
    local.blue_tags,
    var.alarm_tags,
    {
      Metric = "RequestCount"
    }
  )
}

# Error Rate Alarms for Blue Environment
resource "aws_cloudwatch_metric_alarm" "blue_error_rate_high" {
  count               = var.enable_alarms.error_rate ? 1 : 0
  alarm_name          = format(local.alarm_names.error_rate.high, "blue")
  comparison_operator = var.alarm_config.error_rate.comparison_operator
  evaluation_periods  = var.alarm_config.error_rate.evaluation_periods
  datapoints_to_alarm = var.alarm_config.error_rate.datapoints_to_alarm
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period             = var.alarm_config.error_rate.period
  statistic          = var.alarm_config.error_rate.statistic
  threshold          = var.alarm_config.error_rate.high_threshold
  treat_missing_data = var.alarm_config.error_rate.treat_missing_data
  alarm_description  = "${var.alarm_description_prefix} error rate for blue environment"
  alarm_actions      = var.alarm_actions.alarm_actions
  ok_actions         = var.alarm_actions.ok_actions
  insufficient_data_actions = var.alarm_actions.insufficient_data_actions

  dimensions = {
    TargetGroup  = aws_lb_target_group.blue.arn_suffix
    LoadBalancer = split("/", var.alb_listener_arn)[1]
  }

  tags = merge(
    local.blue_tags,
    var.alarm_tags,
    {
      Metric = "ErrorRate"
    }
  )
}

# Latency Alarms for Blue Environment
resource "aws_cloudwatch_metric_alarm" "blue_latency_high" {
  count               = var.enable_alarms.latency ? 1 : 0
  alarm_name          = format(local.alarm_names.latency.high, "blue")
  comparison_operator = var.alarm_config.latency.comparison_operator
  evaluation_periods  = var.alarm_config.latency.evaluation_periods
  datapoints_to_alarm = var.alarm_config.latency.datapoints_to_alarm
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period             = var.alarm_config.latency.period
  statistic          = var.alarm_config.latency.statistic
  threshold          = var.alarm_config.latency.high_threshold
  treat_missing_data = var.alarm_config.latency.treat_missing_data
  alarm_description  = "${var.alarm_description_prefix} latency for blue environment"
  alarm_actions      = var.alarm_actions.alarm_actions
  ok_actions         = var.alarm_actions.ok_actions
  insufficient_data_actions = var.alarm_actions.insufficient_data_actions

  dimensions = {
    TargetGroup  = aws_lb_target_group.blue.arn_suffix
    LoadBalancer = split("/", var.alb_listener_arn)[1]
  }

  tags = merge(
    local.blue_tags,
    var.alarm_tags,
    {
      Metric = "Latency"
    }
  )
}

# Auto Scaling Policies for Blue Environment
resource "aws_autoscaling_policy" "blue_scale_up" {
  name                   = "${local.resource_names.asg.blue}-scale-up"
  scaling_adjustment     = local.scaling_adjustments.scale_up
  adjustment_type        = "ChangeInCapacity"
  cooldown              = var.scaling_policies.cpu_utilization.scale_out_cooldown
  autoscaling_group_name = aws_autoscaling_group.blue.name

  tags = local.blue_tags
}

resource "aws_autoscaling_policy" "blue_scale_down" {
  name                   = "${local.resource_names.asg.blue}-scale-down"
  scaling_adjustment     = local.scaling_adjustments.scale_down
  adjustment_type        = "ChangeInCapacity"
  cooldown              = var.scaling_policies.cpu_utilization.scale_in_cooldown
  autoscaling_group_name = aws_autoscaling_group.blue.name

  tags = local.blue_tags
}

# Auto Scaling Policies for Green Environment
resource "aws_autoscaling_policy" "green_scale_up" {
  name                   = "${local.resource_names.asg.green}-scale-up"
  scaling_adjustment     = local.scaling_adjustments.scale_up
  adjustment_type        = "ChangeInCapacity"
  cooldown              = var.scaling_policies.cpu_utilization.scale_out_cooldown
  autoscaling_group_name = aws_autoscaling_group.green.name

  tags = local.green_tags
}

resource "aws_autoscaling_policy" "green_scale_down" {
  name                   = "${local.resource_names.asg.green}-scale-down"
  scaling_adjustment     = local.scaling_adjustments.scale_down
  adjustment_type        = "ChangeInCapacity"
  cooldown              = var.scaling_policies.cpu_utilization.scale_in_cooldown
  autoscaling_group_name = aws_autoscaling_group.green.name

  tags = local.green_tags
}

# Target Tracking Scaling Policies for Blue Environment
resource "aws_autoscaling_policy" "blue_cpu_target_tracking" {
  count                  = var.scaling_policies.target_tracking.cpu_utilization != null ? 1 : 0
  name                   = "${local.resource_names.asg.blue}-cpu-target-tracking"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.blue.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.scaling_policies.target_tracking.cpu_utilization.target_value
    disable_scale_in = var.scaling_policies.target_tracking.cpu_utilization.disable_scale_in
  }

  estimated_instance_warmup = 300

  tags = local.blue_tags
}

resource "aws_autoscaling_policy" "blue_memory_target_tracking" {
  count                  = var.scaling_policies.target_tracking.memory_utilization != null ? 1 : 0
  name                   = "${local.resource_names.asg.blue}-memory-target-tracking"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.blue.name

  target_tracking_configuration {
    customized_metric_specification {
      metric_name = "MemoryUtilization"
      namespace   = "System/Linux"
      statistic   = "Average"
      unit        = "Percent"
      dimensions {
        name  = "AutoScalingGroupName"
        value = aws_autoscaling_group.blue.name
      }
    }
    target_value = var.scaling_policies.target_tracking.memory_utilization.target_value
    disable_scale_in = var.scaling_policies.target_tracking.memory_utilization.disable_scale_in
  }

  estimated_instance_warmup = 300

  tags = local.blue_tags
}

resource "aws_autoscaling_policy" "blue_request_count_target_tracking" {
  count                  = var.scaling_policies.target_tracking.request_count != null ? 1 : 0
  name                   = "${local.resource_names.asg.blue}-request-count-target-tracking"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.blue.name

  target_tracking_configuration {
    customized_metric_specification {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      statistic   = "Sum"
      unit        = "Count"
      dimensions {
        name  = "TargetGroup"
        value = aws_lb_target_group.blue.arn_suffix
      }
      dimensions {
        name  = "LoadBalancer"
        value = split("/", var.alb_listener_arn)[1]
      }
    }
    target_value = var.scaling_policies.target_tracking.request_count.target_value
    disable_scale_in = var.scaling_policies.target_tracking.request_count.disable_scale_in
  }

  estimated_instance_warmup = 300

  tags = local.blue_tags
}

# Target Tracking Scaling Policies for Green Environment
resource "aws_autoscaling_policy" "green_cpu_target_tracking" {
  count                  = var.scaling_policies.target_tracking.cpu_utilization != null ? 1 : 0
  name                   = "${local.resource_names.asg.green}-cpu-target-tracking"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.green.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.scaling_policies.target_tracking.cpu_utilization.target_value
    disable_scale_in = var.scaling_policies.target_tracking.cpu_utilization.disable_scale_in
  }

  estimated_instance_warmup = 300

  tags = local.green_tags
}

resource "aws_autoscaling_policy" "green_memory_target_tracking" {
  count                  = var.scaling_policies.target_tracking.memory_utilization != null ? 1 : 0
  name                   = "${local.resource_names.asg.green}-memory-target-tracking"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.green.name

  target_tracking_configuration {
    customized_metric_specification {
      metric_name = "MemoryUtilization"
      namespace   = "System/Linux"
      statistic   = "Average"
      unit        = "Percent"
      dimensions {
        name  = "AutoScalingGroupName"
        value = aws_autoscaling_group.green.name
      }
    }
    target_value = var.scaling_policies.target_tracking.memory_utilization.target_value
    disable_scale_in = var.scaling_policies.target_tracking.memory_utilization.disable_scale_in
  }

  estimated_instance_warmup = 300

  tags = local.green_tags
}

resource "aws_autoscaling_policy" "green_request_count_target_tracking" {
  count                  = var.scaling_policies.target_tracking.request_count != null ? 1 : 0
  name                   = "${local.resource_names.asg.green}-request-count-target-tracking"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.green.name

  target_tracking_configuration {
    customized_metric_specification {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      statistic   = "Sum"
      unit        = "Count"
      dimensions {
        name  = "TargetGroup"
        value = aws_lb_target_group.green.arn_suffix
      }
      dimensions {
        name  = "LoadBalancer"
        value = split("/", var.alb_listener_arn)[1]
      }
    }
    target_value = var.scaling_policies.target_tracking.request_count.target_value
    disable_scale_in = var.scaling_policies.target_tracking.request_count.disable_scale_in
  }

  estimated_instance_warmup = 300

  tags = local.green_tags
}

# Custom Metric Target Tracking Policy (if configured)
resource "aws_autoscaling_policy" "blue_custom_metric_target_tracking" {
  count                  = var.scaling_policies.target_tracking.custom_metric != null ? 1 : 0
  name                   = "${local.resource_names.asg.blue}-custom-metric-target-tracking"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.blue.name

  target_tracking_configuration {
    customized_metric_specification {
      metric_name = var.scaling_policies.target_tracking.custom_metric.metric_name
      namespace   = var.scaling_policies.target_tracking.custom_metric.namespace
      statistic   = var.scaling_policies.target_tracking.custom_metric.statistic
      unit        = "Count"

      dynamic "dimensions" {
        for_each = var.scaling_policies.target_tracking.custom_metric.dimensions
        content {
          name  = dimensions.key
          value = dimensions.value
        }
      }
    }
    target_value = var.scaling_policies.target_tracking.custom_metric.target_value
    disable_scale_in = var.scaling_policies.target_tracking.custom_metric.disable_scale_in
  }

  estimated_instance_warmup = 300

  tags = local.blue_tags
}

resource "aws_autoscaling_policy" "green_custom_metric_target_tracking" {
  count                  = var.scaling_policies.target_tracking.custom_metric != null ? 1 : 0
  name                   = "${local.resource_names.asg.green}-custom-metric-target-tracking"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.green.name

  target_tracking_configuration {
    customized_metric_specification {
      metric_name = var.scaling_policies.target_tracking.custom_metric.metric_name
      namespace   = var.scaling_policies.target_tracking.custom_metric.namespace
      statistic   = var.scaling_policies.target_tracking.custom_metric.statistic
      unit        = "Count"

      dynamic "dimensions" {
        for_each = var.scaling_policies.target_tracking.custom_metric.dimensions
        content {
          name  = dimensions.key
          value = dimensions.value
        }
      }
    }
    target_value = var.scaling_policies.target_tracking.custom_metric.target_value
    disable_scale_in = var.scaling_policies.target_tracking.custom_metric.disable_scale_in
  }

  estimated_instance_warmup = 300

  tags = local.green_tags
}

# IAM Role for Blue Environment
resource "aws_iam_role" "blue" {
  name = local.resource_names.iam_role.blue

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

  tags = local.blue_tags
}

# IAM Role Policy for Blue Environment
resource "aws_iam_role_policy" "blue" {
  name = local.resource_names.iam_policy.blue
  role = aws_iam_role.blue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeTags",
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile for Blue Environment
resource "aws_iam_instance_profile" "blue" {
  name = local.resource_names.iam_profile.blue
  role = aws_iam_role.blue.name

  tags = local.blue_tags
}

# IAM Role for Green Environment
resource "aws_iam_role" "green" {
  name = local.resource_names.iam_role.green

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

  tags = local.green_tags
}

# IAM Role Policy for Green Environment
resource "aws_iam_role_policy" "green" {
  name = local.resource_names.iam_policy.green
  role = aws_iam_role.green.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeTags",
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile for Green Environment
resource "aws_iam_instance_profile" "green" {
  name = local.resource_names.iam_profile.green
  role = aws_iam_role.green.name

  tags = local.green_tags
}

module "iam" {
  source      = "../iam"
  name_prefix = var.name_prefix
  tags        = var.tags
}

module "launch_template" {
  source                      = "../launch_template"
  name_prefix                 = var.name_prefix
  ami_id                      = var.ami_id
  instance_config             = var.instance_config
  security_group_ids          = var.security_group_ids
  associate_public_ip         = var.associate_public_ip
  iam_instance_profile_name   = module.iam.ec2_instance_profile_name
  user_data_template_path     = var.user_data_template_path
  user_data_vars              = var.user_data_vars
  tags                        = var.tags
}

module "asg" {
  source                  = "../asg"
  name                    = var.name_prefix
  launch_template_id      = module.launch_template.launch_template_id
  launch_template_version = module.launch_template.launch_template_latest_version
  subnet_ids              = var.subnet_ids
  target_group_arns       = var.target_group_arns
  scaling_config          = var.scaling_config
  scaling_policies        = var.scaling_policies
  tags                    = var.tags
}

module "alarms" {
  source      = "../alarms"
  name_prefix = var.name_prefix
  asg_name    = module.asg.asg_name
  alarm_config = var.alarm_config
  tags        = var.tags
} 