variable "name_prefix" {
  description = "Prefix for the launch template name"
  type        = string
}

variable "ami_id" {
  description = "Optional custom AMI ID. If not provided, latest Amazon Linux 2 AMI will be used"
  type        = string
  default     = null

  validation {
    condition     = var.ami_id == null || can(regex("^ami-[a-z0-9]+$", var.ami_id))
    error_message = "The AMI ID must be a valid AMI ID starting with 'ami-'"
  }
}

variable "instance_config" {
  description = "Configuration for the EC2 instance"
  type = object({
    type = string
    block_device_mappings = list(object({
      device_name = string
      ebs = object({
        volume_size           = number
        volume_type           = string
        iops                  = optional(number)
        throughput            = optional(number)
        encrypted             = bool
        kms_key_id            = optional(string)
        delete_on_termination = bool
        snapshot_id           = optional(string)
      })
      no_device    = optional(string)
      virtual_name = optional(string)
    }))
    metadata_options = object({
      http_endpoint               = string
      http_tokens                 = string
      http_put_response_hop_limit = number
      instance_metadata_tags      = string
    })
  })

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium", "t3.large", "m5.large", "m5.xlarge", "c5.large", "c5.xlarge"], var.instance_config.type)
    error_message = "The instance type must be one of the supported types: t3.micro, t3.small, t3.medium, t3.large, m5.large, m5.xlarge, c5.large, c5.xlarge"
  }

  validation {
    condition     = alltrue([for bdm in var.instance_config.block_device_mappings : can(regex("^/dev/[a-z]+[0-9]*$", bdm.device_name))])
    error_message = "Device names must be valid Linux device names (e.g., /dev/xvda, /dev/sdb)"
  }

  validation {
    condition     = alltrue([for bdm in var.instance_config.block_device_mappings : contains(["gp2", "gp3", "io1", "io2", "standard"], bdm.ebs.volume_type)])
    error_message = "Volume type must be one of: gp2, gp3, io1, io2, standard"
  }
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the instance"
  type        = list(string)

  validation {
    condition     = alltrue([for sg in var.security_group_ids : can(regex("^sg-[a-z0-9]+$", sg))])
    error_message = "Security group IDs must be valid and start with 'sg-'"
  }
}

variable "associate_public_ip" {
  description = "Whether to associate a public IP address with the instance"
  type        = bool
  default     = false
}

variable "iam_instance_profile_name" {
  description = "Name of the IAM instance profile to attach to the instance"
  type        = string
}

variable "user_data_template_path" {
  description = "Path to the user data template file"
  type        = string
}

variable "user_data_vars" {
  description = "Variables to pass to the user data template"
  type        = map(any)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
} 