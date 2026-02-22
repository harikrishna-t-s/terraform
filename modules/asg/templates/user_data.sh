#!/bin/bash

# Update system packages
yum update -y

# Install CloudWatch agent
yum install -y amazon-cloudwatch-agent

# Write CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
${cloudwatch_agent_config}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Install application dependencies
yum install -y java-11-amazon-corretto

# Create application directory
mkdir -p /opt/application

# Download and start application
aws s3 cp s3://${var.artifact_bucket}/${var.artifact_key} /opt/application/app.jar

# Create systemd service
cat > /etc/systemd/system/application.service << EOF
[Unit]
Description=Application Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/application
ExecStart=/usr/bin/java -jar app.jar --server.port=${app_port}
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Start application service
systemctl enable application
systemctl start application

# Configure log rotation
cat > /etc/logrotate.d/application << 'EOF'
/var/log/application.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 ec2-user ec2-user
}
EOF 