# AWS Systems Manager (SSM) Module

This module provides a complete setup for AWS Systems Manager (SSM) to manage EC2 instances, including patch management, maintenance windows, and custom automation.

## Features

- **Patch Management**: Automated patching with configurable baselines and schedules
- **Maintenance Windows**: Scheduled maintenance periods for system updates
- **Custom Automation**: Support for custom SSM documents and automation
- **Hybrid Instance Support**: Optional activation for hybrid instances
- **IAM Integration**: Proper IAM roles and policies for SSM operations

## Usage

```hcl
module "ssm" {
  source = "./modules/ssm"

  environment = "prod"

  # Maintenance Window Configuration
  create_maintenance_window = true
  maintenance_window_schedule = "cron(0 0 ? * SUN *)"  # Every Sunday at midnight
  maintenance_window_duration = 3
  maintenance_window_cutoff   = 1

  # Patch Management Configuration
  create_patch_baseline = true
  patch_approval_days   = 7
  create_patch_association = true
  patch_schedule = "cron(0 0 ? * SUN *)"

  # Custom Automation
  create_custom_document = true
  custom_document_content = <<-EOT
    schemaVersion: '0.3'
    description: 'Custom automation for instance management'
    parameters:
      InstanceId:
        type: String
        description: 'Instance ID to manage'
    mainSteps:
      - name: InstallUpdates
        action: 'aws:runCommand'
        inputs:
          DocumentName: 'AWS-RunPatchBaseline'
          InstanceIds:
            - '{{ InstanceId }}'
          Parameters:
            Operation: 'Install'
  EOT

  tags = {
    Environment = "prod"
    Service     = "ssm"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name | `string` | n/a | yes |
| create_activation | Whether to create SSM activation | `bool` | `false` | no |
| registration_limit | Maximum number of managed instances | `number` | `1000` | no |
| create_maintenance_window | Whether to create a maintenance window | `bool` | `true` | no |
| maintenance_window_schedule | Schedule of the maintenance window | `string` | `cron(0 0 ? * SUN *)` | no |
| maintenance_window_duration | Duration of the maintenance window in hours | `number` | `3` | no |
| maintenance_window_cutoff | Cutoff time before maintenance window ends | `number` | `1` | no |
| create_patch_group | Whether to create a patch group | `bool` | `true` | no |
| create_patch_baseline | Whether to create a patch baseline | `bool` | `true` | no |
| patch_approval_days | Days to wait before approving patches | `number` | `7` | no |
| create_patch_association | Whether to create a patch association | `bool` | `true` | no |
| target_instance_ids | List of instance IDs to target for patching | `list(string)` | `[]` | no |
| patch_schedule | Schedule for patch installation | `string` | `cron(0 0 ? * SUN *)` | no |
| create_custom_document | Whether to create a custom SSM document | `bool` | `false` | no |
| custom_document_content | Content of the custom SSM document | `string` | `""` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Patch Management

The module includes a comprehensive patch management setup:

- **Patch Baseline**: Defines which patches are approved for installation
- **Patch Group**: Groups instances for targeted patching
- **Maintenance Window**: Controls when patches can be installed
- **Patch Schedule**: Defines the frequency of patch installation

## Maintenance Windows

Maintenance windows provide controlled periods for system updates:

- Configurable schedule using cron expressions
- Adjustable duration and cutoff times
- Support for multiple maintenance windows
- Integration with patch management

## Custom Automation

The module supports custom automation through SSM documents:

- YAML-based document format
- Support for multiple steps and actions
- Parameter passing and validation
- Integration with AWS services

## Security

- IAM roles follow least privilege principle
- Secure parameter storage
- Encrypted communications
- Audit logging support

## Additional Resources

- [AWS Systems Manager Documentation](https://docs.aws.amazon.com/systems-manager/latest/userguide/what-is-systems-manager.html)
- [Patch Manager Best Practices](https://docs.aws.amazon.com/systems-manager/latest/userguide/patch-manager-best-practices.html)
- [Maintenance Windows](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-maintenance.html)
- [Automation Documents](https://docs.aws.amazon.com/systems-manager/latest/userguide/automation-documents.html) 