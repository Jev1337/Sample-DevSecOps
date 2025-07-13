#!/bin/bash

# Script to test and fix webhook receiver deployment

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

# Function to test nginx configuration
test_nginx_config() {
    log "🧪 Testing nginx configuration..." "$BLUE"
    
    # Create a temporary container to test the config
    docker run --rm -v "$(pwd)/k8s/webhook-configmap.yaml:/tmp/test.yaml" nginx:alpine sh -c "
        # Extract the nginx config from the configmap
        sed -n '/default.conf: |/,/^[[:space:]]*$/p' /tmp/test.yaml | sed '1d' | sed '/^[[:space:]]*$/d' > /tmp/default.conf
        
        # Test the configuration
        nginx -t -c /dev/null -g 'error_log /dev/stderr; pid /tmp/nginx.pid;' -f /tmp/default.conf
    "
    
    if [ $? -eq 0 ]; then
        log "✅ Nginx configuration is valid!" "$GREEN"
    else
        log "❌ Nginx configuration has errors!" "$RED"
        return 1
    fi
}

# Function to restart webhook receiver
restart_webhook_receiver() {
    log "🔄 Restarting webhook receiver..." "$BLUE"
    
    # Delete existing deployment
    kubectl delete deployment webhook-receiver -n siem --ignore-not-found
    
    # Wait a moment
    sleep 5
    
    # Get external IP
    EXTERNAL_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com)
    log "🌐 Using external IP: $EXTERNAL_IP" "$GREEN"
    
    # Apply configurations
    log "Applying webhook configurations..." "$YELLOW"
    kubectl apply -f k8s/webhook-configmap.yaml
    kubectl apply -f k8s/webhook-deployment.yaml
    
    # Apply ingress with substituted IP
    sed "s/EXTERNAL_IP/${EXTERNAL_IP}/g" k8s/webhook-ingress.yaml | kubectl apply -f -
    
    # Wait for deployment
    log "⏳ Waiting for deployment to be ready..." "$YELLOW"
    kubectl rollout status deployment/webhook-receiver -n siem --timeout=2m
    
    log "✅ Webhook receiver restarted successfully!" "$GREEN"
}

# Function to show logs
show_logs() {
    log "📋 Showing webhook receiver logs..." "$BLUE"
    kubectl logs -n siem deployment/webhook-receiver --tail=50
}

# Function to test webhook endpoint
test_webhook_endpoint() {
    EXTERNAL_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com)
    WEBHOOK_URL="http://webhook.${EXTERNAL_IP}.nip.io/webhook"
    
    log "🧪 Testing webhook endpoint: $WEBHOOK_URL" "$BLUE"
    
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d '{"test": "true", "message": "SIEM webhook test", "timestamp": "'$(date -Iseconds)'"}')
    
    if [ "$response" = "200" ]; then
        log "✅ Webhook endpoint is working!" "$GREEN"
    else
        log "❌ Webhook test failed (HTTP $response)" "$RED"
        log "Checking ingress status..." "$YELLOW"
        kubectl get ingress -n siem
        log "Checking service status..." "$YELLOW"
        kubectl get svc -n siem
    fi
}

# Main menu
while true; do
    echo ""
    log "🛠️  Webhook Receiver Management" "$BLUE"
    log "==============================" "$BLUE"
    echo "  1) Test nginx configuration"
    echo "  2) Restart webhook receiver"
    echo "  3) Show logs"
    echo "  4) Test webhook endpoint"
    echo "  5) Exit"
    echo ""
    read -p "Enter your choice [1-5]: " choice
    
    case $choice in
        1)
            test_nginx_config
            ;;
        2)
            restart_webhook_receiver
            ;;
        3)
            show_logs
            ;;
        4)
            test_webhook_endpoint
            ;;
        5)
            log "👋 Goodbye!" "$GREEN"
            exit 0
            ;;
        *)
            log "❌ Invalid choice. Please try again." "$RED"
            ;;
    esac
done
