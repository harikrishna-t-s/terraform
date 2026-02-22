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

# Application Load Balancer
module "alb" {
  source = "../../modules/alb"

  environment = "example"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.public_subnets

  create_waf = true
  create_monitoring = true

  tags = {
    Environment = "example"
    Service     = "alb"
  }
}

# Launch Template for Blue Environment
resource "aws_launch_template" "blue" {
  name_prefix   = "blue-"
  image_id      = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [aws_security_group.example.id]
  }

  user_data = base64encode(<<-EOT
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
    echo "<h1>Blue Environment</h1>" > /var/www/html/index.html
  EOT
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "blue-instance"
      Environment = "example"
    }
  }
}

# Launch Template for Green Environment
resource "aws_launch_template" "green" {
  name_prefix   = "green-"
  image_id      = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [aws_security_group.example.id]
  }

  user_data = base64encode(<<-EOT
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
    echo "<h1>Green Environment</h1>" > /var/www/html/index.html
  EOT
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "green-instance"
      Environment = "example"
    }
  }
}

# Blue/Green Deployment
module "blue_green" {
  source = "../../modules/blue_green"

  environment = "example"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets

  alb_listener_arn = module.alb.listener_arn

  blue_launch_template_id  = aws_launch_template.blue.id
  green_launch_template_id = aws_launch_template.green.id

  blue_path_patterns  = ["/blue/*"]
  green_path_patterns = ["/green/*"]

  desired_capacity = 2
  max_size        = 4
  min_size        = 1

  # Alarm Configuration
  alarm_config = {
    cpu_utilization = {
      high_threshold = 80
      low_threshold  = 20
      period         = 300
      evaluation_periods = 2
      statistic      = "Average"
    }
    memory_utilization = {
      high_threshold = 80
      low_threshold  = 20
      period         = 300
      evaluation_periods = 2
      statistic      = "Average"
    }
    disk_utilization = {
      high_threshold = 80
      low_threshold  = 20
      period         = 300
      evaluation_periods = 2
      statistic      = "Average"
    }
    request_count = {
      high_threshold = 1000
      period         = 300
      evaluation_periods = 2
      statistic      = "Sum"
    }
    error_rate = {
      high_threshold = 5
      period         = 300
      evaluation_periods = 2
      statistic      = "Average"
    }
    latency = {
      high_threshold = 1
      period         = 300
      evaluation_periods = 2
      statistic      = "Average"
    }
  }

  # Enable/Disable Alarms
  enable_alarms = {
    cpu_utilization = true
    memory_utilization = true
    disk_utilization = true
    request_count = true
    error_rate = true
    latency = true
  }

  # Alarm Actions
  alarm_actions = {
    ok_actions    = []
    alarm_actions = []
  }

  tags = {
    Environment = "example"
    Service     = "blue-green"
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