# AMI Data Source with validation
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

  lifecycle {
    postcondition {
      condition     = self.id != ""
      error_message = "Failed to find a valid Amazon Linux 2 AMI"
    }
  }
}

# Validate AMI ID if provided
locals {
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux_2.id
}

# Launch Template
resource "aws_launch_template" "this" {
  name_prefix   = "${var.name_prefix}-"
  image_id      = local.ami_id
  instance_type = var.instance_config.type

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip
    security_groups            = var.security_group_ids
  }

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  # Enhanced block device mappings with validation
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

  user_data = base64encode(templatefile(var.user_data_template_path, var.user_data_vars))

  tag_specifications {
    resource_type = "instance"
    tags          = var.tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = var.tags
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
} 