# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$", var.vpc_cidr))
    error_message = "VPC CIDR must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }
}

# Subnet Configuration
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$", cidr))])
    error_message = "All public subnet CIDRs must be valid CIDR blocks."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidrs : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$", cidr))])
    error_message = "All private subnet CIDRs must be valid CIDR blocks."
  }
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.5.0/24", "10.0.6.0/24"]
  validation {
    condition     = alltrue([for cidr in var.database_subnet_cidrs : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$", cidr))])
    error_message = "All database subnet CIDRs must be valid CIDR blocks."
  }
}

# Availability Zones
variable "availability_zones" {
  description = "List of Availability Zones to use"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two availability zones are required for high availability."
  }
}

# Environment and Tagging
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets"
  type        = bool
  default     = false
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "vpc_flow_log_retention_days" {
  description = "Number of days to retain VPC Flow Logs"
  type        = number
  default     = 30
}

variable "cost_center" {
  description = "Cost center for cost allocation"
  type        = string
  default     = "Unassigned"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "Unassigned"
}

variable "department" {
  description = "Department responsible for the resources"
  type        = string
  default     = "Unassigned"
}

variable "centralized_log_destination" {
  description = "ARN of the CloudWatch Logs destination for centralized logging"
  type        = string
  default     = ""
}

variable "naming_prefix" {
  description = "Prefix for resource naming"
  type        = string
  default     = "vpc"
}

variable "vpc_flow_log_format" {
  description = "Format for VPC Flow Logs"
  type        = string
  default     = "${version} ${account-id} ${interface-id} ${srcaddr} ${dstaddr} ${srcport} ${dstport} ${protocol} ${packets} ${bytes} ${start} ${end} ${action} ${log-status}"
}

variable "vpc_flow_log_aggregation_interval" {
  description = "Maximum interval of time during which a flow of packets is captured and aggregated into a flow log record"
  type        = number
  default     = 60
} 