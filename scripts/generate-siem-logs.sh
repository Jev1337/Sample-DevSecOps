#!/bin/bash

# SIEM Log Generator for Testing
# This script generates sample logs to populate the SIEM dashboard with test data

set -e

LOG_DIR="/tmp/siem-logs"
SSH_LOG_FILE="$LOG_DIR/auth.log"
K8S_AUDIT_LOG="$LOG_DIR/audit.log"

# Create log directory
mkdir -p "$LOG_DIR"

echo "🔧 Starting SIEM log generator for testing..."

# Function to generate timestamp
get_timestamp() {
    date '+%b %d %H:%M:%S'
}

# Function to generate SSH authentication logs
generate_ssh_logs() {
    echo "📝 Generating SSH authentication logs..."
    
    # Failed SSH attempts
    cat >> "$SSH_LOG_FILE" << EOF
$(get_timestamp) server1 sshd[12345]: Failed password for invalid user admin from 192.168.1.100 port 22 ssh2
$(get_timestamp) server1 sshd[12346]: Failed password for root from 10.0.0.50 port 22 ssh2
$(get_timestamp) server1 sshd[12347]: Invalid user test from 172.16.0.25 port 22
$(get_timestamp) server1 sshd[12348]: authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=192.168.1.200 user=root
$(get_timestamp) server1 sshd[12349]: Failed password for user1 from 203.0.113.10 port 22 ssh2
EOF

    # Successful SSH attempts
    cat >> "$SSH_LOG_FILE" << EOF
$(get_timestamp) server1 sshd[12350]: Accepted password for ubuntu from 192.168.1.10 port 22 ssh2
$(get_timestamp) server1 sshd[12351]: Accepted publickey for admin from 10.0.0.5 port 22 ssh2
EOF

    echo "✅ SSH logs generated: $SSH_LOG_FILE"
}

# Function to generate Kubernetes audit logs
generate_k8s_audit_logs() {
    echo "📝 Generating Kubernetes audit logs..."
    
    cat >> "$K8S_AUDIT_LOG" << EOF
{"kind":"Event","apiVersion":"audit.k8s.io/v1","level":"Request","auditID":"abc123","stage":"ResponseComplete","requestURI":"/api/v1/namespaces/default/pods","verb":"list","user":{"username":"system:serviceaccount:kube-system:kubernetes-dashboard","uid":"def456","groups":["system:serviceaccounts","system:serviceaccounts:kube-system","system:authenticated"]},"sourceIPs":["10.0.0.1"],"userAgent":"kubectl/v1.24.0","objectRef":{"resource":"pods","namespace":"default","apiVersion":"v1"},"responseStatus":{"metadata":{},"code":200},"requestReceivedTimestamp":"$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)","stageTimestamp":"$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"}
{"kind":"Event","apiVersion":"audit.k8s.io/v1","level":"Request","auditID":"xyz789","stage":"ResponseComplete","requestURI":"/api/v1/namespaces/kube-system/secrets","verb":"create","user":{"username":"system:admin","uid":"ghi789","groups":["system:masters","system:authenticated"]},"sourceIPs":["10.0.0.2"],"userAgent":"kubectl/v1.24.0","objectRef":{"resource":"secrets","namespace":"kube-system","name":"test-secret","apiVersion":"v1"},"responseStatus":{"metadata":{},"code":201},"requestReceivedTimestamp":"$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)","stageTimestamp":"$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"}
{"kind":"Event","apiVersion":"audit.k8s.io/v1","level":"Request","auditID":"mno456","stage":"ResponseComplete","requestURI":"/api/v1/namespaces/monitoring/pods","verb":"delete","user":{"username":"system:serviceaccount:monitoring:grafana","uid":"jkl012","groups":["system:serviceaccounts","system:serviceaccounts:monitoring","system:authenticated"]},"sourceIPs":["10.0.0.3"],"userAgent":"kubectl/v1.24.0","objectRef":{"resource":"pods","namespace":"monitoring","name":"test-pod","apiVersion":"v1"},"responseStatus":{"metadata":{},"code":200},"requestReceivedTimestamp":"$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)","stageTimestamp":"$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"}
EOF

    echo "✅ Kubernetes audit logs generated: $K8S_AUDIT_LOG"
}

# Function to send webhook test events
send_webhook_events() {
    echo "📝 Sending webhook test events..."
    
    # Check if webhook service is running
    if curl -s http://localhost:5001/health > /dev/null 2>&1; then
        echo "📡 Webhook service is running, sending test events..."
        
        # GitHub-style webhook event
        curl -s -X POST http://localhost:5001/webhook \
            -H "Content-Type: application/json" \
            -H "X-GitHub-Event: push" \
            -d '{
                "repository": {
                    "full_name": "test/repo"
                },
                "pusher": {
                    "name": "testuser"
                },
                "commits": [
                    {
                        "message": "Security fix: Updated authentication"
                    }
                ]
            }' > /dev/null
        
        # GitLab-style webhook event
        curl -s -X POST http://localhost:5001/webhook \
            -H "Content-Type: application/json" \
            -H "X-GitLab-Event: push" \
            -d '{
                "project": {
                    "path_with_namespace": "security/monitoring"
                },
                "user_name": "devops-user",
                "commits": [
                    {
                        "message": "Added security monitoring rules"
                    }
                ]
            }' > /dev/null
        
        echo "✅ Webhook events sent successfully"
    else
        echo "⚠️  Webhook service not accessible at localhost:5001"
    fi
}

# Function to update Docker Compose to mount log files
update_docker_compose() {
    echo "🔧 Updating Alloy container to read generated logs..."
    
    # Check if we need to mount the log files
    if ! grep -q "/tmp/siem-logs" docker-compose.yml 2>/dev/null; then
        echo "Adding log volume mounts to docker-compose.yml..."
        # This would require manual editing of docker-compose.yml
        echo "Please add these volume mounts to the alloy service in docker-compose.yml:"
        echo "  - $LOG_DIR:/tmp/siem-logs:ro"
        echo "  - /var/log:/host/var/log:ro"
    fi
}

# Function to restart services
restart_services() {
    echo "🔄 Restarting Docker Compose services..."
    docker-compose restart alloy
    sleep 5
    echo "✅ Services restarted"
}

# Function to verify log ingestion
verify_logs() {
    echo "🔍 Verifying log ingestion in Loki..."
    
    # Wait a moment for logs to be processed
    sleep 10
    
    # Query Loki for different log sources
    echo "Checking for webhook logs..."
    curl -s "http://localhost:3100/loki/api/v1/query_range?query={job=\"webhook-receiver\"}" | jq '.data.result | length'
    
    echo "Checking for SSH logs..."
    curl -s "http://localhost:3100/loki/api/v1/query_range?query={job=\"node-logs\"}" | jq '.data.result | length'
    
    echo "Checking for Kubernetes audit logs..."
    curl -s "http://localhost:3100/loki/api/v1/query_range?query={job=\"kubernetes-audit\"}" | jq '.data.result | length'
}

# Main execution
main() {
    echo "🚀 SIEM Test Data Generator"
    echo "=========================="
    
    # Generate sample logs
    generate_ssh_logs
    generate_k8s_audit_logs
    
    # Send webhook events
    send_webhook_events
    
    # Update configuration notes
    update_docker_compose
    
    echo ""
    echo "📋 Next Steps:"
    echo "1. Update your docker-compose.yml to mount the log directories:"
    echo "   volumes:"
    echo "     - $LOG_DIR:/tmp/siem-logs:ro"
    echo "     - /var/log:/host/var/log:ro"
    echo ""
    echo "2. Update the Alloy config to read from these paths:"
    echo "   - /tmp/siem-logs/auth.log (for SSH logs)"
    echo "   - /tmp/siem-logs/audit.log (for K8s audit logs)"
    echo ""
    echo "3. Restart the alloy service:"
    echo "   docker-compose restart alloy"
    echo ""
    echo "4. Check Grafana SIEM dashboard for populated data"
    echo ""
    echo "✅ Test data generation complete!"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
