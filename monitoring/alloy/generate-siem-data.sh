#!/bin/bash

# SIEM Log Generator - Creates sample security events for testing
# This script generates sample logs to populate the SIEM dashboard

LOG_DIR="/tmp/siem-logs"
AUTH_LOG="$LOG_DIR/auth.log"
AUDIT_LOG="$LOG_DIR/audit.log"

# Create log directory
mkdir -p "$LOG_DIR"

# Function to generate timestamp
get_timestamp() {
    date '+%b %d %H:%M:%S'
}

# Function to generate random IP
get_random_ip() {
    echo "192.168.$(( RANDOM % 255 )).$(( RANDOM % 255 ))"
}

# Function to generate SSH authentication logs
generate_ssh_logs() {
    local timestamp=$(get_timestamp)
    local ip=$(get_random_ip)
    local users=("admin" "root" "ubuntu" "test" "hacker" "malicious")
    local user=${users[$RANDOM % ${#users[@]}]}
    
    # Generate failed authentication
    if [[ $((RANDOM % 3)) -eq 0 ]]; then
        echo "${timestamp} localhost sshd[$$]: Failed password for ${user} from ${ip} port 22 ssh2" >> "$AUTH_LOG"
    else
        # Generate successful authentication
        echo "${timestamp} localhost sshd[$$]: Accepted password for ${user} from ${ip} port 22 ssh2" >> "$AUTH_LOG"
    fi
}

# Function to generate Kubernetes audit logs
generate_k8s_audit() {
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local users=("system:admin" "user@example.com" "service-account" "anonymous")
    local user=${users[$RANDOM % ${#users[@]}]}
    local verbs=("get" "list" "create" "update" "delete" "patch")
    local verb=${verbs[$RANDOM % ${#verbs[@]}]}
    local resources=("pods" "services" "secrets" "configmaps" "deployments")
    local resource=${resources[$RANDOM % ${#resources[@]}]}
    local namespaces=("default" "kube-system" "monitoring" "jenkins")
    local namespace=${namespaces[$RANDOM % ${#namespaces[@]}]}
    
    cat >> "$AUDIT_LOG" << EOF
{"kind":"Event","apiVersion":"audit.k8s.io/v1","level":"Request","auditID":"$(uuidgen)","stage":"ResponseComplete","requestURI":"/api/v1/namespaces/${namespace}/${resource}","verb":"${verb}","user":{"username":"${user}","groups":["system:authenticated"]},"sourceIPs":["$(get_random_ip)"],"userAgent":"kubectl/v1.28.0","objectRef":{"resource":"${resource}","namespace":"${namespace}","name":"test-${resource}","apiVersion":"v1"},"responseStatus":{"metadata":{},"code":200},"requestReceivedTimestamp":"${timestamp}","stageTimestamp":"${timestamp}"}
EOF
}

# Function to send logs to Loki directly
send_to_loki() {
    local log_entry="$1"
    local job="$2"
    local level="${3:-info}"
    
    local timestamp_ns=$(date +%s%N)
    local loki_url="http://localhost:3100/loki/api/v1/push"
    
    curl -s -X POST "$loki_url" \
        -H "Content-Type: application/json" \
        -d "{
            \"streams\": [
                {
                    \"stream\": {
                        \"job\": \"${job}\",
                        \"level\": \"${level}\",
                        \"generator\": \"siem-test\"
                    },
                    \"values\": [
                        [\"${timestamp_ns}\", \"${log_entry}\"]
                    ]
                }
            ]
        }" > /dev/null 2>&1
}

# Main execution
echo "🛡️  Generating SIEM test data..."

# Generate logs for the past hour
for i in {1..50}; do
    # Generate SSH logs
    generate_ssh_logs
    
    # Send SSH log directly to Loki
    if [[ $((RANDOM % 4)) -eq 0 ]]; then
        # Failed SSH attempt
        local ip=$(get_random_ip)
        local user="hacker$((RANDOM % 10))"
        send_to_loki "$(get_timestamp) localhost sshd: Failed password for ${user} from ${ip} port 22 ssh2" "node-logs" "warning"
    fi
    
    # Generate K8s audit logs
    generate_k8s_audit
    
    # Send K8s audit log directly to Loki
    if [[ $((RANDOM % 3)) -eq 0 ]]; then
        local user="user$((RANDOM % 5))@example.com"
        local action="delete"
        local resource="secret"
        send_to_loki "{\"user\":\"${user}\",\"verb\":\"${action}\",\"resource\":\"${resource}\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)\"}" "kubernetes-audit" "warning"
    fi
    
    sleep 0.1
done

echo "✅ Generated sample SIEM data!"
echo "📊 Check your Grafana SIEM dashboard at: http://localhost:3000"
echo "🔍 Logs are also available at:"
echo "   - SSH logs: $AUTH_LOG"
echo "   - K8s audit: $AUDIT_LOG"
