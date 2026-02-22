variable "environment" {
  description = "Environment name"
  type        = string
  default     = "example"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 4
}

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 1
} 