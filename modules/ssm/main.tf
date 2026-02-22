# SSM Activation for hybrid instances (if needed)
resource "aws_ssm_activation" "example" {
  count = var.create_activation ? 1 : 0

  name               = "${var.environment}-ssm-activation"
  description        = "SSM activation for ${var.environment} instances"
  iam_role           = aws_iam_role.ssm_activation.arn
  registration_limit = var.registration_limit
  tags               = var.tags
}

# IAM role for SSM activation
resource "aws_iam_role" "ssm_activation" {
  count = var.create_activation ? 1 : 0

  name = "${var.environment}-ssm-activation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policy for SSM activation
resource "aws_iam_role_policy_attachment" "ssm_activation" {
  count = var.create_activation ? 1 : 0

  role       = aws_iam_role.ssm_activation[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# SSM Maintenance Window
resource "aws_ssm_maintenance_window" "example" {
  count = var.create_maintenance_window ? 1 : 0

  name              = "${var.environment}-maintenance-window"
  description       = "Maintenance window for ${var.environment} instances"
  schedule          = var.maintenance_window_schedule
  duration          = var.maintenance_window_duration
  cutoff            = var.maintenance_window_cutoff
  allow_unassociated_targets = false
  enabled           = true

  tags = var.tags
}

# SSM Maintenance Window Target
resource "aws_ssm_maintenance_window_target" "example" {
  count = var.create_maintenance_window && var.asg_name != null ? 1 : 0

  window_id     = aws_ssm_maintenance_window.example[0].id
  name          = "${var.environment}-maintenance-window-target"
  description   = "Target for ASG instances"

  targets {
    key    = "tag:aws:autoscaling:groupName"
    values = [var.asg_name]
  }

  resource_type = "INSTANCE"
}

# SSM Maintenance Window Task
resource "aws_ssm_maintenance_window_task" "patch" {
  count = var.create_maintenance_window ? 1 : 0

  window_id        = aws_ssm_maintenance_window.example[0].id
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-ApplyPatchBaseline"
  priority         = 1
  service_role_arn = aws_iam_role.ssm_maintenance.arn

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.example[0].id]
  }

  task_invocation_parameters {
    run_command_parameters {
      parameter {
        name   = "Operation"
        values = ["Install"]
      }
      parameter {
        name   = "SnapshotId"
        values = [""]
      }
      parameter {
        name   = "InstallOverrideList"
        values = [""]
      }
      parameter {
        name   = "BaselineOverride"
        values = [""]
      }
      parameter {
        name   = "InstallOnlyBase"
        values = ["false"]
      }
    }
  }
}

# SSM Maintenance Window Task for health checks
resource "aws_ssm_maintenance_window_task" "health_check" {
  count = var.create_maintenance_window ? 1 : 0

  window_id        = aws_ssm_maintenance_window.example[0].id
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunShellScript"
  priority         = 2
  service_role_arn = aws_iam_role.ssm_maintenance.arn

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.example[0].id]
  }

  task_invocation_parameters {
    run_command_parameters {
      parameter {
        name   = "commands"
        values = [
          "systemctl status amazon-ssm-agent",
          "systemctl status amazon-cloudwatch-agent",
          "df -h",
          "free -m",
          "top -b -n 1 | head -n 5"
        ]
      }
      parameter {
        name   = "executionTimeout"
        values = ["3600"]
      }
    }
  }
}

# SSM Maintenance Window Task for log rotation
resource "aws_ssm_maintenance_window_task" "log_rotation" {
  count = var.create_maintenance_window ? 1 : 0

  window_id        = aws_ssm_maintenance_window.example[0].id
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunShellScript"
  priority         = 3
  service_role_arn = aws_iam_role.ssm_maintenance.arn

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.example[0].id]
  }

  task_invocation_parameters {
    run_command_parameters {
      parameter {
        name   = "commands"
        values = [
          "find /var/log -type f -name '*.gz' -mtime +30 -delete",
          "find /var/log -type f -name '*.old' -mtime +30 -delete",
          "find /var/log -type f -name '*.1' -mtime +30 -delete"
        ]
      }
      parameter {
        name   = "executionTimeout"
        values = ["3600"]
      }
    }
  }
}

# IAM role for maintenance window tasks
resource "aws_iam_role" "ssm_maintenance" {
  name = "${var.environment}-ssm-maintenance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policy for maintenance window tasks
resource "aws_iam_role_policy_attachment" "ssm_maintenance" {
  role       = aws_iam_role.ssm_maintenance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMMaintenanceWindowRole"
}

# SSM Patch Group
resource "aws_ssm_patch_group" "example" {
  count = var.create_patch_group ? 1 : 0

  baseline_id = aws_ssm_patch_baseline.example[0].id
  patch_group = "${var.environment}-patch-group"
}

# SSM Patch Baseline
resource "aws_ssm_patch_baseline" "example" {
  count = var.create_patch_baseline ? 1 : 0

  name             = "${var.environment}-patch-baseline"
  description      = "Patch baseline for ${var.environment} instances"
  operating_system = "AMAZON_LINUX_2"

  approval_rule {
    approve_after_days = var.patch_approval_days

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Security", "Bugfix"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Critical", "Important"]
    }
  }

  tags = var.tags
}

# SSM Association for patch management
resource "aws_ssm_association" "patch" {
  count = var.create_patch_association ? 1 : 0

  name = "AWS-ApplyPatchBaseline"

  targets {
    key    = "tag:aws:autoscaling:groupName"
    values = [var.asg_name]
  }

  parameters = {
    Operation = "Install"
    SnapshotId = ""
    InstallOverrideList = ""
    BaselineOverride = ""
    InstallOnlyBase = "false"
  }

  schedule_expression = var.patch_schedule
}

# SSM Document for custom automation
resource "aws_ssm_document" "example" {
  count = var.create_custom_document ? 1 : 0

  name            = "${var.environment}-custom-automation"
  document_type   = "Automation"
  document_format = "YAML"
  content         = var.custom_document_content

  tags = var.tags
}

# SSM Association for custom automation
resource "aws_ssm_association" "custom" {
  count = var.create_custom_document ? 1 : 0

  name = aws_ssm_document.example[0].name

  targets {
    key    = "tag:aws:autoscaling:groupName"
    values = [var.asg_name]
  }

  parameters = var.custom_document_parameters

  schedule_expression = var.custom_document_schedule
}

# SSM Document for instance refresh
resource "aws_ssm_document" "instance_refresh" {
  count = var.create_instance_refresh_document ? 1 : 0

  name            = "${var.environment}-instance-refresh"
  document_type   = "Automation"
  document_format = "YAML"
  content         = <<-EOT
    schemaVersion: '0.3'
    description: 'Automation document for instance refresh'
    parameters:
      ASGName:
        type: String
        description: 'Name of the Auto Scaling Group'
      InstanceId:
        type: String
        description: 'Instance ID to refresh'
    mainSteps:
      - name: StartInstanceRefresh
        action: 'aws:executeAwsApi'
        inputs:
          Service: autoscaling
          Api: StartInstanceRefresh
          AutoScalingGroupName: '{{ ASGName }}'
          Preferences:
            InstanceWarmup: 300
            MinHealthyPercentage: 90
      - name: WaitForRefresh
        action: 'aws:waitForAwsResourceProperty'
        inputs:
          Service: autoscaling
          Api: DescribeInstanceRefreshes
          AutoScalingGroupName: '{{ ASGName }}'
          PropertySelector: '$.InstanceRefreshes[0].Status'
          DesiredValues:
            - Completed
            - Failed
            - Cancelled
      - name: CheckRefreshStatus
        action: 'aws:executeAwsApi'
        inputs:
          Service: autoscaling
          Api: DescribeInstanceRefreshes
          AutoScalingGroupName: '{{ ASGName }}'
        outputs:
          - Name: RefreshStatus
            Selector: '$.InstanceRefreshes[0].Status'
            Type: String
      - name: FailIfNotCompleted
        action: 'aws:assertAwsResourceProperty'
        inputs:
          Service: autoscaling
          Api: DescribeInstanceRefreshes
          AutoScalingGroupName: '{{ ASGName }}'
          PropertySelector: '$.InstanceRefreshes[0].Status'
          DesiredValues:
            - Completed
  EOT

  tags = var.tags
}

# SSM Association for instance refresh
resource "aws_ssm_association" "instance_refresh" {
  count = var.create_instance_refresh_document ? 1 : 0

  name = aws_ssm_document.instance_refresh[0].name

  targets {
    key    = "tag:aws:autoscaling:groupName"
    values = [var.asg_name]
  }

  parameters = {
    "ASGName" = [var.asg_name]
  }

  schedule_expression = var.instance_refresh_schedule
} 