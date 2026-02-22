#!/bin/bash
set -e

# Function to complete lifecycle hook
complete_lifecycle_hook() {
  local hook_name=$1
  local instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
  local region=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
  local asg_name=$(aws autoscaling describe-auto-scaling-instances --instance-ids $instance_id --region $region --query 'AutoScalingInstances[0].AutoScalingGroupName' --output text)

  aws autoscaling complete-lifecycle-action \
    --lifecycle-hook-name $hook_name \
    --auto-scaling-group-name $asg_name \
    --instance-id $instance_id \
    --lifecycle-action-result CONTINUE \
    --region $region
}

# Handle launch lifecycle hook
handle_launch_hook() {
  # Wait for system to be ready
  while ! systemctl is-system-running --quiet; do
    sleep 5
  done

  # Complete launch hook
  complete_lifecycle_hook "launch-hook"
}

# Handle termination lifecycle hook
handle_termination_hook() {
  # Perform cleanup tasks
  systemctl stop app
  systemctl stop health
  systemctl stop amazon-cloudwatch-agent

  # Complete termination hook
  complete_lifecycle_hook "terminate-hook"
}

# Start launch hook handler in background
handle_launch_hook &

# Update system packages
yum update -y

# Install required packages
yum install -y amazon-cloudwatch-agent jq aws-cli

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/var/log/messages",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/secure",
            "log_group_name": "/var/log/secure",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  },
  "metrics": {
    "metrics_collected": {
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "/"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Start CloudWatch Agent
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Create application directory
mkdir -p /opt/app

# Set up application environment
cat > /opt/app/.env << EOF
ENVIRONMENT=${environment}
AWS_REGION=${region}
EOF

# Set up application service
cat > /etc/systemd/system/app.service << 'EOF'
[Unit]
Description=Application Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/app
ExecStart=/usr/bin/python3 app.py
Restart=always
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

# Enable and start application service
systemctl enable app
systemctl start app

# Create health check endpoint
cat > /opt/app/health.sh << 'EOF'
#!/bin/bash
if systemctl is-active --quiet app; then
  exit 0
else
  exit 1
fi
EOF

chmod +x /opt/app/health.sh

# Set up health check service
cat > /etc/systemd/system/health.service << 'EOF'
[Unit]
Description=Health Check Service
After=app.service

[Service]
Type=simple
ExecStart=/opt/app/health.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start health check service
systemctl enable health
systemctl start health

# Install and configure web server
yum install -y httpd
systemctl enable httpd
systemctl start httpd

# Create a simple index page
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Welcome</title>
</head>
<body>
    <h1>Welcome to the ${environment} environment!</h1>
    <p>This is a sample application running on AWS.</p>
    <p>Instance Type: $(curl -s http://169.254.169.254/latest/meta-data/instance-type)</p>
    <p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
</body>
</html>
EOF

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Set up termination hook handler
cat > /etc/systemd/system/termination-hook.service << 'EOF'
[Unit]
Description=ASG Termination Hook Handler
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/handle-termination-hook.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Create termination hook handler script
cat > /usr/local/bin/handle-termination-hook.sh << 'EOF'
#!/bin/bash
handle_termination_hook
EOF

chmod +x /usr/local/bin/handle-termination-hook.sh
systemctl enable termination-hook 