provider "aws" {
  region = "us-west-2"
}

# VPC and networking setup
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "example-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = "example"
    Terraform   = "true"
  }
}

# CloudWatch agent setup
module "cloudwatch_agent" {
  source = "../../modules/cloudwatch-agent"

  environment = "example"
  region     = "us-west-2"

  metrics_collection_interval = 60

  metrics_config = {
    metrics = {
      metrics_collected = {
        mem = {
          measurement = ["mem_used_percent"]
        }
        disk = {
          measurement = ["disk_used_percent"]
          resources   = ["/"]
        }
      }
    }
  }

  logs_config = {
    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path = "/var/log/application/*.log"
              log_group_name = "/ec2/application"
              log_stream_name = "{instance_id}"
            }
          ]
        }
      }
    }
  }

  tags = {
    Environment = "example"
    Service     = "monitoring"
  }
}

# SSM setup
module "ssm" {
  source = "../../modules/ssm"

  environment = var.environment
  asg_name    = aws_autoscaling_group.example.name

  create_maintenance_window = true
  maintenance_window_schedule = "cron(0 0 ? * SUN *)"  # Every Sunday at midnight
  maintenance_window_duration = 3
  maintenance_window_cutoff   = 1

  create_patch_baseline = true
  patch_approval_days   = 7

  create_patch_association = true
  patch_schedule          = "cron(0 0 ? * SUN *)"  # Every Sunday at midnight

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
      - name: CheckHealth
        action: 'aws:runCommand'
        inputs:
          DocumentName: 'AWS-RunShellScript'
          InstanceIds:
            - '{{ InstanceId }}'
          Parameters:
            commands:
              - 'systemctl status amazon-ssm-agent'
              - 'systemctl status amazon-cloudwatch-agent'
  EOT

  custom_document_parameters = {
    "InstanceId" = ["{{TARGET_ID}}"]
  }

  custom_document_schedule = "cron(0 0 ? * SUN *)"  # Every Sunday at midnight

  # Enable instance refresh
  create_instance_refresh_document = true
  instance_refresh_schedule        = "cron(0 0 ? * MON *)"  # Every Monday at midnight

  tags = {
    Environment = var.environment
    Service     = "ssm"
  }
}

# Add IAM permissions for instance refresh
resource "aws_iam_role_policy" "instance_refresh" {
  name = "${var.environment}-instance-refresh-policy"
  role = module.cloudwatch_agent.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:StartInstanceRefresh",
          "autoscaling:DescribeInstanceRefreshes",
          "autoscaling:CancelInstanceRefresh"
        ]
        Resource = aws_autoscaling_group.example.arn
      }
    ]
  })
}

# Launch Template
resource "aws_launch_template" "example" {
  name_prefix   = "example-"
  image_id      = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [aws_security_group.example.id]
  }

  iam_instance_profile {
    name = module.cloudwatch_agent.iam_role_name
  }

  user_data = base64encode(<<-EOT
    #!/bin/bash
    # Install SSM agent
    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent

    # Install and configure CloudWatch agent
    ${module.cloudwatch_agent.user_data}

    # Tag the instance with ASG name for SSM targeting
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    aws ec2 create-tags --resources $INSTANCE_ID --tags Key=aws:autoscaling:groupName,Value=${aws_autoscaling_group.example.name} --region ${var.region}
  EOT
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "example-instance"
      Environment = "example"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "example" {
  name                = "example-asg"
  vpc_zone_identifier = module.vpc.private_subnets
  desired_capacity    = 2
  max_size           = 4
  min_size           = 1

  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "example-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "aws:autoscaling:groupName"
    value               = "example-asg"
    propagate_at_launch = true
  }
}

# Security Group
resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Security group for example instances"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "example-sg"
    Environment = "example"
  }
}

# Add SSM permissions to instance role
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = module.cloudwatch_agent.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Add SSM patch management permissions
resource "aws_iam_role_policy_attachment" "ssm_patch" {
  role       = module.cloudwatch_agent.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMPatchBaseline"
} 