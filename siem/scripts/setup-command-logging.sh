#!/bin/bash

# Enhanced Command Logging Setup for SIEM
# This script sets up comprehensive command logging for security monitoring

set -e

echo "Setting up enhanced command logging for SIEM..."

# Create log directory if it doesn't exist
mkdir -p /var/log/siem

# Setup bash command logging with detailed information
cat >> /etc/bash.bashrc << 'EOF'

# SIEM Command Logging Configuration
export HISTTIMEFORMAT="%F %T $(whoami) "
export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTCONTROL=ignoredups:ignorespace

# Log all commands with timestamp, user, PID, and command
log_command() {
    local cmd=$(history 1 | sed 's/^[ ]*[0-9]*[ ]*[0-9-]*[ ]*[0-9:]*[ ]*[a-zA-Z0-9_-]*[ ]*//')
    if [ ! -z "$cmd" ] && [ "$cmd" != "log_command" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') $(whoami) $$ $cmd" >> /var/log/bash.log
    fi
}

# Set up command logging for interactive shells
if [ "$PS1" ]; then
    export PROMPT_COMMAND="history -a; log_command"
fi
EOF

# Create log files with proper permissions
touch /var/log/bash.log
touch /var/log/history.log
chmod 644 /var/log/bash.log /var/log/history.log

# Setup logrotate for command logs
cat > /etc/logrotate.d/siem-commands << 'EOF'
/var/log/bash.log /var/log/history.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        # Restart rsyslog if running
        systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}
EOF

# Setup audit rules for system calls if auditd is available
if command -v auditctl >/dev/null 2>&1; then
    echo "Setting up audit rules for command execution..."
    
    # Add rules for command execution monitoring
    auditctl -a always,exit -F arch=b64 -S execve -k command_execution 2>/dev/null || true
    auditctl -a always,exit -F arch=b32 -S execve -k command_execution 2>/dev/null || true
    
    # Add rules for file access monitoring
    auditctl -w /etc/passwd -p wa -k user_modification 2>/dev/null || true
    auditctl -w /etc/shadow -p wa -k user_modification 2>/dev/null || true
    auditctl -w /etc/group -p wa -k user_modification 2>/dev/null || true
    
    # Add rules for sudo usage
    auditctl -w /var/log/auth.log -p wa -k auth_log 2>/dev/null || true
    auditctl -w /var/log/secure -p wa -k auth_log 2>/dev/null || true
    
    echo "Audit rules configured successfully"
else
    echo "auditctl not available, skipping audit rules setup"
fi

# Setup rsyslog configuration for command logging
cat > /etc/rsyslog.d/50-siem-commands.conf << 'EOF'
# SIEM Command Logging Configuration
# Log bash commands to separate file
$ModLoad imfile
$InputFileName /var/log/bash.log
$InputFileTag bash-commands:
$InputFileStateFile stat-bash-commands
$InputFileSeverity info
$InputFileFacility local0
$InputRunFileMonitor

# Forward to local syslog
local0.* /var/log/siem/commands.log
EOF

# Restart rsyslog to apply configuration
systemctl restart rsyslog 2>/dev/null || service rsyslog restart 2>/dev/null || true

# Create a test entry
echo "$(date '+%Y-%m-%d %H:%M:%S') system $$ SIEM command logging setup completed" >> /var/log/bash.log

echo "Enhanced command logging setup completed successfully!"
echo "Logs will be available at:"
echo "  - /var/log/bash.log (real-time command execution)"
echo "  - /var/log/history.log (command history)"
echo "  - /var/log/siem/commands.log (processed commands)"
echo ""
echo "Note: Users need to log out and log back in for bash logging to take effect"