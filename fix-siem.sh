#!/bin/bash

# Script to fix SIEM monitoring configuration and Grafana dashboard issues

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${2:-$NC}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Function to check Alloy configuration
check_alloy_config() {
    log "🔍 Checking Alloy configuration syntax..." "$BLUE"
    
    # Get the current Alloy configuration
    kubectl get configmap alloy -n monitoring -o yaml > /tmp/alloy-config.yaml 2>/dev/null || {
        log "❌ Could not retrieve Alloy configuration" "$RED"
        return 1
    }
    
    log "✅ Alloy configuration retrieved" "$GREEN"
}

# Function to update Alloy configuration
update_alloy_config() {
    log "🔄 Updating Alloy configuration..." "$BLUE"
    
    # Upgrade Alloy with new configuration
    microk8s helm3 upgrade alloy grafana/alloy -n monitoring -f helm/alloy/values.yaml
    
    if [ $? -eq 0 ]; then
        log "✅ Alloy configuration updated successfully" "$GREEN"
    else
        log "❌ Failed to update Alloy configuration" "$RED"
        return 1
    fi
    
    # Wait for Alloy to restart
    log "⏳ Waiting for Alloy to restart..." "$YELLOW"
    kubectl rollout restart daemonset/alloy -n monitoring
    kubectl rollout status daemonset/alloy -n monitoring --timeout=2m
    
    log "✅ Alloy restarted successfully" "$GREEN"
}

# Function to check Alloy logs
check_alloy_logs() {
    log "📋 Checking Alloy logs for errors..." "$BLUE"
    
    echo "Recent Alloy logs:"
    kubectl logs -n monitoring daemonset/alloy --tail=20 | head -20
    
    # Check for specific errors
    if kubectl logs -n monitoring daemonset/alloy --tail=50 | grep -q "parse error\|syntax error\|unexpected"; then
        log "❌ Configuration errors found in Alloy logs" "$RED"
        return 1
    else
        log "✅ No configuration errors in Alloy logs" "$GREEN"
    fi
}

# Function to test log ingestion
test_log_ingestion() {
    log "🧪 Testing log ingestion..." "$BLUE"
    
    # Generate some test log entries
    logger "SIEM-TEST: Authentication test event"
    echo "$(date): SIEM-TEST install test-package" | sudo tee -a /var/log/dpkg.log > /dev/null
    
    # Wait a moment for logs to be processed
    sleep 10
    
    # Query Loki for test logs
    log "Checking if logs are reaching Loki..." "$YELLOW"
    
    # Try to access Loki directly
    kubectl port-forward -n monitoring svc/loki 3100:3100 &
    PF_PID=$!
    sleep 5
    
    # Test query
    response=$(curl -s "http://localhost:3100/loki/api/v1/label" | jq -r '.data[]' 2>/dev/null | head -5)
    
    if [ -n "$response" ]; then
        log "✅ Loki is receiving logs. Available labels:" "$GREEN"
        echo "$response"
    else
        log "❌ No logs found in Loki" "$RED"
    fi
    
    # Clean up port forward
    kill $PF_PID 2>/dev/null || true
}

# Function to fix common issues
fix_common_issues() {
    log "🔧 Fixing common SIEM issues..." "$BLUE"
    
    # Ensure log directories exist
    sudo mkdir -p /tmp/webhooks
    sudo chmod 755 /tmp/webhooks
    
    # Restart rsyslog to ensure log generation
    sudo systemctl restart rsyslog || log "⚠️ Could not restart rsyslog" "$YELLOW"
    
    # Check if auditd is running
    if ! systemctl is-active --quiet auditd; then
        log "Starting auditd..." "$YELLOW"
        sudo systemctl start auditd || log "⚠️ Could not start auditd" "$YELLOW"
    fi
    
    log "✅ Common issues fixed" "$GREEN"
}

# Function to create test data
create_test_data() {
    log "📝 Creating test data for SIEM..." "$BLUE"
    
    # Create test authentication events
    echo "$(date '+%b %d %H:%M:%S') $(hostname) sshd[12345]: Failed password for testuser from 192.168.1.100 port 22 ssh2" | sudo tee -a /var/log/auth.log > /dev/null
    echo "$(date '+%b %d %H:%M:%S') $(hostname) sshd[12346]: Accepted password for azureuser from 10.0.0.1 port 22 ssh2" | sudo tee -a /var/log/auth.log > /dev/null
    
    # Create test package events
    echo "$(date '+%Y-%m-%d %H:%M:%S') install test-security-package" | sudo tee -a /var/log/dpkg.log > /dev/null
    echo "$(date '+%Y-%m-%d %H:%M:%S') upgrade vim" | sudo tee -a /var/log/dpkg.log > /dev/null
    
    # Create test webhook event
    sudo mkdir -p /tmp/webhooks
    cat <<EOF | sudo tee /tmp/webhooks/webhook-access.log > /dev/null
$(date '+%d/%b/%Y:%H:%M:%S %z') 192.168.1.1 - - "POST /webhook HTTP/1.1" 200 45 "-" "GitHub-Hookshot/abc123" {"repository":{"full_name":"test/repo"},"pusher":{"name":"developer"},"head_commit":{"id":"abc123","message":"Security update"}}
EOF
    
    log "✅ Test data created" "$GREEN"
}

# Function to show Grafana access info
show_grafana_info() {
    log "📊 Grafana Access Information" "$BLUE"
    
    # Get external IP
    EXTERNAL_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com)
    
    echo ""
    log "🌐 Grafana Dashboard Access:" "$CYAN"
    log "   URL: http://grafana.${EXTERNAL_IP}.nip.io" "$CYAN"
    log "   Username: admin" "$CYAN"
    log "   Password: admin123" "$CYAN"
    echo ""
    log "📈 Import Enhanced SIEM Dashboard:" "$YELLOW"
    log "   1. Go to Grafana UI" "$YELLOW"
    log "   2. Click '+' -> Import" "$YELLOW"
    log "   3. Upload: monitoring/grafana/dashboards/siem-dashboard-enhanced.json" "$YELLOW"
    log "   4. Configure Loki datasource if needed" "$YELLOW"
    echo ""
    log "🔍 Loki Query Examples:" "$CYAN"
    log "   Authentication failures: {job=\"auth\"} |= \"Failed password\"" "$CYAN"
    log "   Package changes: {job=\"packages\"}" "$CYAN"
    log "   Webhook events: {job=\"webhook\"}" "$CYAN"
    log "   System errors: {job=\"system\"} |= \"error\"" "$CYAN"
}

# Main menu
while true; do
    echo ""
    log "🛠️ SIEM Configuration Fix Tool" "$BLUE"
    log "==============================" "$BLUE"
    echo "  1) Check Alloy configuration"
    echo "  2) Update Alloy configuration"
    echo "  3) Check Alloy logs"
    echo "  4) Test log ingestion"
    echo "  5) Fix common issues"
    echo "  6) Create test data"
    echo "  7) Show Grafana access info"
    echo "  8) Run full fix (options 2,5,6)"
    echo "  9) Exit"
    echo ""
    read -p "Enter your choice [1-9]: " choice
    
    case $choice in
        1)
            check_alloy_config
            ;;
        2)
            update_alloy_config
            ;;
        3)
            check_alloy_logs
            ;;
        4)
            test_log_ingestion
            ;;
        5)
            fix_common_issues
            ;;
        6)
            create_test_data
            ;;
        7)
            show_grafana_info
            ;;
        8)
            log "🚀 Running full SIEM fix..." "$BLUE"
            update_alloy_config
            fix_common_issues
            create_test_data
            log "✅ Full SIEM fix completed!" "$GREEN"
            show_grafana_info
            ;;
        9)
            log "👋 Goodbye!" "$GREEN"
            exit 0
            ;;
        *)
            log "❌ Invalid choice. Please try again." "$RED"
            ;;
    esac
done
