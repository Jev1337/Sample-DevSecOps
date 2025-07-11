#!/bin/bash

# Git Webhook Setup Script for SIEM Integration
# This script helps configure GitHub webhooks to send events to the SIEM system

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${2:-$NC}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Get external IP
get_external_ip() {
    EXTERNAL_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com)
    if [ -z "$EXTERNAL_IP" ]; then
        log "❌ Could not determine external IP address" "$RED"
        exit 1
    fi
    echo "$EXTERNAL_IP"
}

# Test webhook endpoint
test_webhook() {
    local webhook_url="$1"
    log "🧪 Testing webhook endpoint..." "$YELLOW"
    
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$webhook_url" \
        -H "Content-Type: application/json" \
        -d '{"test": "true", "message": "SIEM webhook test", "timestamp": "'$(date -Iseconds)'"}')
    
    if [ "$response" = "200" ]; then
        log "✅ Webhook endpoint is working!" "$GREEN"
        return 0
    else
        log "❌ Webhook test failed (HTTP $response)" "$RED"
        return 1
    fi
}

# Generate GitHub webhook configuration
generate_github_config() {
    local webhook_url="$1"
    
    cat <<EOF

🔗 GitHub Webhook Configuration
===============================

1. Go to your GitHub repository settings
2. Navigate to "Webhooks" section
3. Click "Add webhook"
4. Configure as follows:

   Payload URL: $webhook_url
   Content type: application/json
   Secret: (optional, for additional security)
   
   Which events would you like to trigger this webhook?
   ✅ Just the push event
   ✅ Send me everything (for comprehensive SIEM)
   
5. Click "Add webhook"

📊 SIEM Integration
==================

Your webhook events will be:
- Captured by the webhook receiver
- Logged to /tmp/webhooks/webhook-*.log
- Processed by Alloy for log parsing
- Stored in Loki with proper labels
- Visualized in Grafana SIEM dashboard

🔍 Monitoring Code Changes
=========================

The SIEM will track:
- Repository push events
- Commit information
- Author details
- Branch changes
- File modifications

EOF
}

# Main execution
main() {
    log "🛡️ SIEM Webhook Setup for DevSecOps" "$BLUE"
    log "====================================" "$BLUE"
    
    # Get external IP
    EXTERNAL_IP=$(get_external_ip)
    log "🌐 Detected external IP: $EXTERNAL_IP" "$GREEN"
    
    # Construct webhook URL
    WEBHOOK_URL="http://webhook.${EXTERNAL_IP}.nip.io/webhook"
    
    # Test the webhook
    if test_webhook "$WEBHOOK_URL"; then
        log "🎯 Webhook endpoint ready for configuration" "$GREEN"
    else
        log "⚠️  Webhook endpoint not ready yet. Make sure SIEM stack is deployed." "$YELLOW"
        log "   Run: ./setup.sh and select option 7 (Deploy SIEM Stack)" "$YELLOW"
    fi
    
    # Generate configuration instructions
    generate_github_config "$WEBHOOK_URL"
    
    # Additional test endpoint
    log "🧪 Manual Test Command:" "$BLUE"
    echo "curl -X POST $WEBHOOK_URL \\"
    echo "  -H \"Content-Type: application/json\" \\"
    echo "  -d '{\"test\": \"manual\", \"repository\": {\"full_name\": \"test/repo\"}, \"pusher\": {\"name\": \"testuser\"}}'"
    echo ""
    
    log "📈 Dashboard Access:" "$BLUE"
    log "   Import 'siem-dashboard.json' into Grafana at:" "$YELLOW"
    log "   http://grafana.${EXTERNAL_IP}.nip.io" "$YELLOW"
    log "   Username: admin, Password: admin123" "$YELLOW"
}

# Run the script
main "$@"
