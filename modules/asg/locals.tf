locals {
  # Resource naming
  name_prefix = "asg-${var.environment}"
  
  # Common tags for all resources
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "asg"
    }
  )

  # CloudWatch alarm thresholds
  alarm_thresholds = {
    cpu_high    = 80
    cpu_low     = 20
    memory_high = 85
    disk_high   = 85
  }

  # Scaling policy adjustments
  scaling_adjustments = {
    scale_up   = 1
    scale_down = -1
  }
} 