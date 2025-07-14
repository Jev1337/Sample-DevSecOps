#!/bin/bash

# SIEM Testing Script
# This script generates test security events to validate SIEM functionality

set -e

echo "🧪 SIEM Security Testing Script"
echo "==============================="

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${2:-$NC}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Function to test SSH authentication monitoring
test_ssh_monitoring() {
    log "🔐 Testing SSH Authentication Monitoring..." "$BLUE"
    
    # Generate failed SSH attempts (for demonstration)
    log "Generating test SSH events..." "$YELLOW"
    
    # Test auth.log entry (simulated)
    sudo logger -p auth.info "sshd[12345]: Failed password for testuser from 192.168.1.100 port 22 ssh2"
    sudo logger -p auth.info "sshd[12346]: Accepted password for admin from 192.168.1.10 port 22 ssh2"
    sudo logger -p auth.warning "sshd[12347]: Failed password for root from 10.0.0.50 port 22 ssh2"
    
    log "✅ SSH test events generated" "$GREEN"
}

# Function to test package management monitoring
test_package_monitoring() {
    log "📦 Testing Package Management Monitoring..." "$BLUE"
    
    # Generate package management events
    log "Generating test package events..." "$YELLOW"
    
    # Simulate package operations
    echo "$(date '+%Y-%m-%d %H:%M:%S') PACKAGE_AUDIT: operation=install package=curl version=7.68.0 user=admin pid=$$ ppid=$PPID" | sudo tee -a /var/log/apt/security-audit.log
    echo "$(date '+%Y-%m-%d %H:%M:%S') PACKAGE_AUDIT: operation=upgrade package=openssh-server version=8.2p1 user=admin pid=$$ ppid=$PPID" | sudo tee -a /var/log/apt/security-audit.log
    
    # Send to syslog
    logger -t "APT_SECURITY_AUDIT" "operation=install package=curl version=7.68.0 user=admin"
    logger -t "APT_SECURITY_AUDIT" "operation=upgrade package=openssh-server version=8.2p1 user=admin"
    
    log "✅ Package management test events generated" "$GREEN"
}

# Function to test audit events
test_audit_monitoring() {
    log "🔍 Testing Audit Event Monitoring..." "$BLUE"
    
    # Generate audit events
    log "Generating test audit events..." "$YELLOW"
    
    # Simulate audit log entries
    sudo logger -p local6.info "type=USER_AUTH msg=audit($(date +%s).000:1234): pid=5678 uid=0 auid=1000 ses=1 msg='op=PAM:authentication grantors=pam_unix acct=\"testuser\" exe=\"/usr/sbin/sshd\" hostname=192.168.1.100 addr=192.168.1.100 terminal=ssh res=failed'"
    sudo logger -p local6.info "type=SYSCALL msg=audit($(date +%s).000:1235): arch=c000003e syscall=257 success=yes exit=3 a0=ffffff9c a1=7fff1234abcd a2=0 a3=0 items=1 ppid=1 pid=5679 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=1 comm=\"cat\" exe=\"/bin/cat\" key=\"access\""
    
    log "✅ Audit test events generated" "$GREEN"
}

# Function to test application security events
test_application_security() {
    log "🚨 Testing Application Security Events..." "$BLUE"
    
    # Generate application security events
    log "Generating test application security events..." "$YELLOW"
    
    # Send test webhook events
    WEBHOOK_URL="http://localhost:5000/webhook"  # Adjust as needed
    
    # Test security risk in commit message
    curl -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -H "X-Hub-Signature-256: sha256=$(echo -n '{"commits":[{"message":"fix password vulnerability in auth module"}]}' | openssl dgst -sha256 -hmac 'siem-webhook-secret-2024' | cut -d' ' -f2)" \
        -d '{"event":"push","commits":[{"message":"fix password vulnerability in auth module","added":["auth/config.py"],"modified":["Dockerfile"]}],"pusher":{"name":"testuser"},"ref":"refs/heads/main"}' \
        2>/dev/null || log "⚠️  Webhook endpoint not reachable" "$YELLOW"
    
    # Generate Flask application logs with security events
    kubectl logs -n flask-app deployment/flask-app | head -n 5 || log "⚠️  Flask app not deployed" "$YELLOW"
    
    log "✅ Application security test events generated" "$GREEN"
}

# Function to test Falco runtime security
test_falco_security() {
    log "🛡️  Testing Falco Runtime Security..." "$BLUE"
    
    # Check if Falco is running
    if microk8s kubectl get daemonset falco -n security &>/dev/null; then
        log "Falco is deployed, checking for security events..." "$YELLOW"
        
        # Get recent Falco logs
        FALCO_LOGS=$(microk8s kubectl logs -n security daemonset/falco --tail=10 2>/dev/null || echo "No recent logs")
        
        if [[ "$FALCO_LOGS" != "No recent logs" ]]; then
            log "Recent Falco events:" "$GREEN"
            echo "$FALCO_LOGS"
        else
            log "No recent Falco events (this is normal for a quiet system)" "$YELLOW"
        fi
    else
        log "⚠️  Falco not deployed" "$YELLOW"
    fi
}

# Function to test fail2ban
test_fail2ban() {
    log "🚫 Testing Fail2ban Integration..." "$BLUE"
    
    if command -v fail2ban-client &> /dev/null; then
        log "Checking fail2ban status..." "$YELLOW"
        sudo fail2ban-client status || log "⚠️  Fail2ban not running" "$YELLOW"
        
        # Check SSH jail status
        sudo fail2ban-client status sshd 2>/dev/null || log "⚠️  SSH jail not configured" "$YELLOW"
        
        log "✅ Fail2ban status checked" "$GREEN"
    else
        log "⚠️  Fail2ban not installed" "$YELLOW"
    fi
}

# Function to validate SIEM data flow
test_data_flow() {
    log "📊 Testing SIEM Data Flow..." "$BLUE"
    
    # Check if Alloy is collecting logs
    if microk8s kubectl get daemonset alloy -n monitoring &>/dev/null; then
        log "Checking Alloy log collection..." "$YELLOW"
        
        # Check Alloy logs for errors
        ALLOY_LOGS=$(microk8s kubectl logs -n monitoring daemonset/alloy --tail=20 2>/dev/null | grep -i error || echo "No errors found")
        
        if [[ "$ALLOY_LOGS" == "No errors found" ]]; then
            log "✅ Alloy is running without errors" "$GREEN"
        else
            log "⚠️  Alloy errors detected:" "$YELLOW"
            echo "$ALLOY_LOGS"
        fi
    else
        log "⚠️  Alloy not deployed" "$YELLOW"
    fi
    
    # Check Loki connectivity
    if microk8s kubectl get statefulset loki -n monitoring &>/dev/null; then
        log "Checking Loki status..." "$YELLOW"
        
        LOKI_STATUS=$(microk8s kubectl get pods -n monitoring -l app.kubernetes.io/name=loki --no-headers 2>/dev/null | awk '{print $3}' | head -1)
        
        if [[ "$LOKI_STATUS" == "Running" ]]; then
            log "✅ Loki is running" "$GREEN"
        else
            log "⚠️  Loki status: $LOKI_STATUS" "$YELLOW"
        fi
    else
        log "⚠️  Loki not deployed" "$YELLOW"
    fi
}

# Function to check dashboard availability
test_dashboards() {
    log "📈 Testing Dashboard Availability..." "$BLUE"
    
    # Check if dashboards are imported
    if microk8s kubectl get configmap siem-security-dashboard -n monitoring &>/dev/null; then
        log "✅ SIEM Security Dashboard ConfigMap exists" "$GREEN"
    else
        log "⚠️  SIEM Security Dashboard not found" "$YELLOW"
    fi
    
    if microk8s kubectl get configmap system-audit-dashboard -n monitoring &>/dev/null; then
        log "✅ System Audit Dashboard ConfigMap exists" "$GREEN"
    else
        log "⚠️  System Audit Dashboard not found" "$YELLOW"
    fi
    
    # Check Grafana connectivity
    if microk8s kubectl get deployment grafana -n monitoring &>/dev/null; then
        GRAFANA_STATUS=$(microk8s kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers 2>/dev/null | awk '{print $3}' | head -1)
        
        if [[ "$GRAFANA_STATUS" == "Running" ]]; then
            log "✅ Grafana is running" "$GREEN"
            log "💡 Access dashboards at http://grafana.local (admin/admin123)" "$BLUE"
        else
            log "⚠️  Grafana status: $GRAFANA_STATUS" "$YELLOW"
        fi
    else
        log "⚠️  Grafana not deployed" "$YELLOW"
    fi
}

# Main test execution
main() {
    log "Starting SIEM functionality tests..." "$BLUE"
    echo ""
    
    # Create necessary directories
    sudo mkdir -p /var/log/apt
    sudo mkdir -p /var/log/webhook
    
    # Run tests
    test_ssh_monitoring
    echo ""
    
    test_package_monitoring
    echo ""
    
    test_audit_monitoring
    echo ""
    
    test_application_security
    echo ""
    
    test_falco_security
    echo ""
    
    test_fail2ban
    echo ""
    
    test_data_flow
    echo ""
    
    test_dashboards
    echo ""
    
    log "🎉 SIEM testing completed!" "$GREEN"
    echo ""
    log "📋 Summary:" "$BLUE"
    log "  - Security events have been generated for testing" "$CYAN"
    log "  - Check Grafana dashboards for visualized events" "$CYAN"
    log "  - Review component status above for any issues" "$CYAN"
    log "  - Events may take 1-2 minutes to appear in dashboards" "$CYAN"
    echo ""
    log "🔗 Access Points:" "$BLUE"
    log "  - Grafana: http://grafana.local" "$CYAN"
    log "  - SIEM Dashboard: Import siem/dashboards/siem-security-dashboard.json" "$CYAN"
    log "  - System Audit Dashboard: Import siem/dashboards/system-audit-dashboard.json" "$CYAN"
}

# Run tests
main "$@"
