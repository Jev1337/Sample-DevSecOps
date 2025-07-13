#!/bin/bash

# SIEM Host Setup Script
# This script configures SIEM monitoring on the host system

set -e

echo "🛡️ SIEM Host Monitoring Setup"
echo "==============================="
echo ""

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    echo "⚠️  Please run this script as a regular user, not as root."
    echo "   The script will prompt for sudo when needed."
    exit 1
fi

# Check if Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo "📦 Installing Ansible..."
    sudo apt-get update
    sudo apt-get install -y ansible
    echo "✅ Ansible installed successfully"
fi

# Check if we're in the correct directory
if [ ! -f "ansible/playbooks/siem.yml" ]; then
    echo "❌ Error: Please run this script from the Sample-DevSecOps root directory"
    echo "   Current directory: $(pwd)"
    echo "   Expected file: ansible/playbooks/siem.yml"
    exit 1
fi

echo ""
echo "🚀 Running SIEM configuration playbook..."
echo "   This will configure:"
echo "   - System log collection and rotation"
echo "   - SSH monitoring and fail2ban protection"
echo "   - Audit logging setup"
echo "   - Security monitoring scripts"
echo ""

# Navigate to ansible directory and run playbook
cd ansible
ansible-playbook -i inventory playbooks/siem.yml --ask-become-pass

echo ""
echo "✅ SIEM Host Monitoring setup completed!"
echo ""
echo "🔗 Your SIEM monitoring now includes:"
echo "   - SSH authentication logs (/var/log/auth.log)"
echo "   - System event logs (/var/log/syslog)"
echo "   - Security audit logs (/var/log/audit/audit.log)"
echo "   - Fail2ban protection against brute force attacks"
echo "   - Automated log rotation and cleanup"
echo ""
echo "📊 View security events in Grafana:"
echo "   - Dashboard: 'SIEM Security Dashboard'"
echo "   - URL: http://grafana.YOUR_IP.nip.io"
echo ""
echo "🔗 Git webhook monitoring is available at:"
echo "   - http://webhook.YOUR_IP.nip.io/webhook"
echo ""
echo "⚡ SIEM monitoring is now active!"
