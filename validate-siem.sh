#!/bin/bash

# SIEM Validation Script
# Comprehensive validation of SIEM deployment and functionality

set -e

echo "🔍 SIEM Deployment Validation Script"
echo "===================================="

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

log() {
    echo -e "${2:-$NC}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

test_result() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [[ "$result" == "PASS" ]]; then
        log "✅ $test_name: $message" "$GREEN"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log "❌ $test_name: $message" "$RED"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Test 1: Verify MicroK8s cluster is running
test_microk8s_cluster() {
    log "Testing MicroK8s cluster status..." "$BLUE"
    
    if microk8s status --wait-ready >/dev/null 2>&1; then
        test_result "MicroK8s Cluster" "PASS" "Cluster is ready"
    else
        test_result "MicroK8s Cluster" "FAIL" "Cluster is not ready"
    fi
}

# Test 2: Verify required namespaces exist
test_namespaces() {
    log "Testing required namespaces..." "$BLUE"
    
    required_namespaces=("monitoring" "security" "flask-app")
    
    for namespace in "${required_namespaces[@]}"; do
        if microk8s kubectl get namespace "$namespace" >/dev/null 2>&1; then
            test_result "Namespace $namespace" "PASS" "Namespace exists"
        else
            test_result "Namespace $namespace" "FAIL" "Namespace missing"
        fi
    done
}

# Test 3: Verify SIEM components are deployed
test_siem_components() {
    log "Testing SIEM component deployments..." "$BLUE"
    
    # Check Alloy DaemonSet
    if microk8s kubectl get daemonset alloy -n monitoring >/dev/null 2>&1; then
        desired=$(microk8s kubectl get daemonset alloy -n monitoring -o jsonpath='{.status.desiredNumberScheduled}')
        ready=$(microk8s kubectl get daemonset alloy -n monitoring -o jsonpath='{.status.numberReady}')
        
        if [[ "$desired" == "$ready" && "$ready" -gt 0 ]]; then
            test_result "Alloy DaemonSet" "PASS" "All $ready/$desired pods ready"
        else
            test_result "Alloy DaemonSet" "FAIL" "Only $ready/$desired pods ready"
        fi
    else
        test_result "Alloy DaemonSet" "FAIL" "DaemonSet not found"
    fi
    
    # Check Loki StatefulSet
    if microk8s kubectl get statefulset loki -n monitoring >/dev/null 2>&1; then
        ready=$(microk8s kubectl get statefulset loki -n monitoring -o jsonpath='{.status.readyReplicas}')
        replicas=$(microk8s kubectl get statefulset loki -n monitoring -o jsonpath='{.spec.replicas}')
        
        if [[ "$ready" == "$replicas" && "$ready" -gt 0 ]]; then
            test_result "Loki StatefulSet" "PASS" "All $ready/$replicas replicas ready"
        else
            test_result "Loki StatefulSet" "FAIL" "Only $ready/$replicas replicas ready"
        fi
    else
        test_result "Loki StatefulSet" "FAIL" "StatefulSet not found"
    fi
    
    # Check Grafana Deployment
    if microk8s kubectl get deployment grafana -n monitoring >/dev/null 2>&1; then
        ready=$(microk8s kubectl get deployment grafana -n monitoring -o jsonpath='{.status.readyReplicas}')
        replicas=$(microk8s kubectl get deployment grafana -n monitoring -o jsonpath='{.spec.replicas}')
        
        if [[ "$ready" == "$replicas" && "$ready" -gt 0 ]]; then
            test_result "Grafana Deployment" "PASS" "All $ready/$replicas replicas ready"
        else
            test_result "Grafana Deployment" "FAIL" "Only $ready/$replicas replicas ready"
        fi
    else
        test_result "Grafana Deployment" "FAIL" "Deployment not found"
    fi
    
    # Check Falco DaemonSet
    if microk8s kubectl get daemonset falco -n security >/dev/null 2>&1; then
        desired=$(microk8s kubectl get daemonset falco -n security -o jsonpath='{.status.desiredNumberScheduled}')
        ready=$(microk8s kubectl get daemonset falco -n security -o jsonpath='{.status.numberReady}')
        
        if [[ "$desired" == "$ready" && "$ready" -gt 0 ]]; then
            test_result "Falco DaemonSet" "PASS" "All $ready/$desired pods ready"
        else
            test_result "Falco DaemonSet" "FAIL" "Only $ready/$desired pods ready"
        fi
    else
        test_result "Falco DaemonSet" "FAIL" "DaemonSet not found"
    fi
}

# Test 4: Verify services are accessible
test_services() {
    log "Testing service accessibility..." "$BLUE"
    
    # Test Loki service
    if microk8s kubectl get service loki -n monitoring >/dev/null 2>&1; then
        cluster_ip=$(microk8s kubectl get service loki -n monitoring -o jsonpath='{.spec.clusterIP}')
        port=$(microk8s kubectl get service loki -n monitoring -o jsonpath='{.spec.ports[0].port}')
        
        if curl -s --max-time 5 "http://$cluster_ip:$port/ready" >/dev/null 2>&1; then
            test_result "Loki Service" "PASS" "Service responding on $cluster_ip:$port"
        else
            test_result "Loki Service" "FAIL" "Service not responding"
        fi
    else
        test_result "Loki Service" "FAIL" "Service not found"
    fi
    
    # Test Grafana service
    if microk8s kubectl get service grafana -n monitoring >/dev/null 2>&1; then
        cluster_ip=$(microk8s kubectl get service grafana -n monitoring -o jsonpath='{.spec.clusterIP}')
        port=$(microk8s kubectl get service grafana -n monitoring -o jsonpath='{.spec.ports[0].port}')
        
        if curl -s --max-time 5 "http://$cluster_ip:$port/api/health" | grep -q "ok"; then
            test_result "Grafana Service" "PASS" "Service responding on $cluster_ip:$port"
        else
            test_result "Grafana Service" "FAIL" "Service not responding properly"
        fi
    else
        test_result "Grafana Service" "FAIL" "Service not found"
    fi
}

# Test 5: Verify external access
test_external_access() {
    log "Testing external access..." "$BLUE"
    
    # Test LoadBalancer services
    services=("grafana" "loki")
    
    for service in "${services[@]}"; do
        if microk8s kubectl get service "${service}-loadbalancer" -n monitoring >/dev/null 2>&1; then
            external_ip=$(microk8s kubectl get service "${service}-loadbalancer" -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
            port=$(microk8s kubectl get service "${service}-loadbalancer" -n monitoring -o jsonpath='{.spec.ports[0].port}')
            
            if [[ -n "$external_ip" && "$external_ip" != "null" ]]; then
                test_result "$service LoadBalancer" "PASS" "External IP: $external_ip:$port"
            else
                test_result "$service LoadBalancer" "FAIL" "External IP not assigned"
            fi
        else
            test_result "$service LoadBalancer" "FAIL" "LoadBalancer service not found"
        fi
    done
    
    # Test Ingress resources
    ingress_resources=("grafana-ingress" "loki-ingress")
    
    for ingress in "${ingress_resources[@]}"; do
        if microk8s kubectl get ingress "$ingress" -n monitoring >/dev/null 2>&1; then
            host=$(microk8s kubectl get ingress "$ingress" -n monitoring -o jsonpath='{.spec.rules[0].host}')
            test_result "$ingress" "PASS" "Configured for host: $host"
        else
            test_result "$ingress" "FAIL" "Ingress not found"
        fi
    done
}

# Test 6: Verify log collection
test_log_collection() {
    log "Testing log collection..." "$BLUE"
    
    # Check if Alloy is collecting logs
    alloy_pod=$(microk8s kubectl get pods -n monitoring -l app.kubernetes.io/name=alloy -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [[ -n "$alloy_pod" ]]; then
        # Check Alloy logs for successful log collection
        log_output=$(microk8s kubectl logs "$alloy_pod" -n monitoring --tail=50 2>/dev/null)
        
        if echo "$log_output" | grep -q "logs.*sent"; then
            test_result "Log Collection" "PASS" "Alloy is sending logs successfully"
        elif echo "$log_output" | grep -q -i error; then
            test_result "Log Collection" "FAIL" "Errors detected in Alloy logs"
        else
            test_result "Log Collection" "WARN" "No clear indication of log flow"
        fi
    else
        test_result "Log Collection" "FAIL" "Alloy pod not found"
    fi
}

# Test 7: Verify Loki data ingestion
test_loki_ingestion() {
    log "Testing Loki data ingestion..." "$BLUE"
    
    # Get Loki service endpoint
    loki_ip=$(microk8s kubectl get service loki -n monitoring -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
    loki_port=$(microk8s kubectl get service loki -n monitoring -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
    
    if [[ -n "$loki_ip" && -n "$loki_port" ]]; then
        # Query Loki for recent logs
        query_result=$(curl -s --max-time 10 "http://$loki_ip:$loki_port/loki/api/v1/query?query={job=\"alloy/logs\"}&limit=1" 2>/dev/null)
        
        if echo "$query_result" | grep -q "streams"; then
            test_result "Loki Ingestion" "PASS" "Loki is receiving log data"
        else
            test_result "Loki Ingestion" "FAIL" "No log data found in Loki"
        fi
    else
        test_result "Loki Ingestion" "FAIL" "Cannot connect to Loki service"
    fi
}

# Test 8: Verify Falco security monitoring
test_falco_monitoring() {
    log "Testing Falco security monitoring..." "$BLUE"
    
    # Check if Falco is running and generating events
    falco_pod=$(microk8s kubectl get pods -n security -l app.kubernetes.io/name=falco -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [[ -n "$falco_pod" ]]; then
        # Check Falco logs
        falco_logs=$(microk8s kubectl logs "$falco_pod" -n security --tail=20 2>/dev/null)
        
        if echo "$falco_logs" | grep -q -E "(Falco initialized|Rules loaded)"; then
            test_result "Falco Monitoring" "PASS" "Falco is running and rules are loaded"
        elif echo "$falco_logs" | grep -q -i error; then
            test_result "Falco Monitoring" "FAIL" "Errors detected in Falco"
        else
            test_result "Falco Monitoring" "WARN" "Falco status unclear"
        fi
    else
        test_result "Falco Monitoring" "FAIL" "Falco pod not found"
    fi
}

# Test 9: Verify dashboard configurations
test_dashboards() {
    log "Testing dashboard configurations..." "$BLUE"
    
    # Check for dashboard ConfigMaps
    dashboards=("siem-security-dashboard" "system-audit-dashboard")
    
    for dashboard in "${dashboards[@]}"; do
        if microk8s kubectl get configmap "$dashboard" -n monitoring >/dev/null 2>&1; then
            # Check if ConfigMap has JSON data
            json_data=$(microk8s kubectl get configmap "$dashboard" -n monitoring -o jsonpath='{.data.*}' 2>/dev/null)
            
            if echo "$json_data" | grep -q "dashboard"; then
                test_result "Dashboard $dashboard" "PASS" "Dashboard configuration found"
            else
                test_result "Dashboard $dashboard" "FAIL" "Invalid dashboard configuration"
            fi
        else
            test_result "Dashboard $dashboard" "FAIL" "Dashboard ConfigMap not found"
        fi
    done
}

# Test 10: Verify webhook receiver
test_webhook_receiver() {
    log "Testing webhook receiver..." "$BLUE"
    
    # Check if webhook receiver is deployed
    if microk8s kubectl get deployment webhook-receiver -n flask-app >/dev/null 2>&1; then
        ready=$(microk8s kubectl get deployment webhook-receiver -n flask-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
        replicas=$(microk8s kubectl get deployment webhook-receiver -n flask-app -o jsonpath='{.spec.replicas}' 2>/dev/null)
        
        if [[ "$ready" == "$replicas" && "$ready" -gt 0 ]]; then
            test_result "Webhook Receiver" "PASS" "Deployment ready ($ready/$replicas)"
            
            # Test webhook endpoint
            webhook_ip=$(microk8s kubectl get service webhook-receiver -n flask-app -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
            webhook_port=$(microk8s kubectl get service webhook-receiver -n flask-app -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
            
            if curl -s --max-time 5 "http://$webhook_ip:$webhook_port/health" | grep -q "healthy"; then
                test_result "Webhook Endpoint" "PASS" "Endpoint responding at $webhook_ip:$webhook_port"
            else
                test_result "Webhook Endpoint" "FAIL" "Endpoint not responding"
            fi
        else
            test_result "Webhook Receiver" "FAIL" "Deployment not ready ($ready/$replicas)"
        fi
    else
        test_result "Webhook Receiver" "FAIL" "Deployment not found"
    fi
}

# Test 11: Verify system hardening
test_system_hardening() {
    log "Testing system hardening components..." "$BLUE"
    
    # Check if fail2ban is installed and running
    if command -v fail2ban-client >/dev/null 2>&1; then
        if sudo fail2ban-client status >/dev/null 2>&1; then
            test_result "Fail2ban" "PASS" "Service is running"
        else
            test_result "Fail2ban" "FAIL" "Service not running"
        fi
    else
        test_result "Fail2ban" "FAIL" "Not installed"
    fi
    
    # Check if auditd is running
    if systemctl is-active auditd >/dev/null 2>&1; then
        test_result "Auditd" "PASS" "Service is running"
    else
        test_result "Auditd" "FAIL" "Service not running"
    fi
}

# Test 12: Verify log file permissions and directories
test_log_permissions() {
    log "Testing log file permissions..." "$BLUE"
    
    # Check critical log directories
    log_dirs=("/var/log" "/var/log/audit" "/var/log/apt")
    
    for dir in "${log_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            permissions=$(stat -c "%a" "$dir" 2>/dev/null)
            if [[ "$permissions" =~ ^[0-7][0-7][0-7]$ ]]; then
                test_result "Log Directory $dir" "PASS" "Permissions: $permissions"
            else
                test_result "Log Directory $dir" "FAIL" "Invalid permissions: $permissions"
            fi
        else
            test_result "Log Directory $dir" "FAIL" "Directory does not exist"
        fi
    done
}

# Test 13: Performance and resource usage
test_resource_usage() {
    log "Testing resource usage..." "$BLUE"
    
    # Check node resource usage
    node_cpu=$(microk8s kubectl top nodes --no-headers 2>/dev/null | awk '{print $3}' | head -1)
    node_memory=$(microk8s kubectl top nodes --no-headers 2>/dev/null | awk '{print $5}' | head -1)
    
    if [[ -n "$node_cpu" && -n "$node_memory" ]]; then
        cpu_percent=$(echo "$node_cpu" | tr -d '%')
        memory_percent=$(echo "$node_memory" | tr -d '%')
        
        if [[ "$cpu_percent" -lt 80 ]]; then
            test_result "Node CPU Usage" "PASS" "CPU usage: $node_cpu"
        else
            test_result "Node CPU Usage" "WARN" "High CPU usage: $node_cpu"
        fi
        
        if [[ "$memory_percent" -lt 80 ]]; then
            test_result "Node Memory Usage" "PASS" "Memory usage: $node_memory"
        else
            test_result "Node Memory Usage" "WARN" "High memory usage: $node_memory"
        fi
    else
        test_result "Resource Metrics" "FAIL" "Unable to get resource metrics"
    fi
}

# Main execution
main() {
    log "Starting comprehensive SIEM validation..." "$BLUE"
    echo ""
    
    # Run all tests
    test_microk8s_cluster
    echo ""
    
    test_namespaces
    echo ""
    
    test_siem_components
    echo ""
    
    test_services
    echo ""
    
    test_external_access
    echo ""
    
    test_log_collection
    echo ""
    
    test_loki_ingestion
    echo ""
    
    test_falco_monitoring
    echo ""
    
    test_dashboards
    echo ""
    
    test_webhook_receiver
    echo ""
    
    test_system_hardening
    echo ""
    
    test_log_permissions
    echo ""
    
    test_resource_usage
    echo ""
    
    # Summary
    log "🎯 SIEM Validation Summary:" "$BLUE"
    echo "=========================="
    log "Total Tests: $TOTAL_TESTS" "$CYAN"
    log "Passed: $PASSED_TESTS" "$GREEN"
    log "Failed: $FAILED_TESTS" "$RED"
    
    success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    log "Success Rate: ${success_rate}%" "$CYAN"
    
    echo ""
    
    if [[ "$FAILED_TESTS" -eq 0 ]]; then
        log "🎉 All tests passed! SIEM setup is fully operational." "$GREEN"
        log "📊 Access your dashboards at:" "$BLUE"
        log "   - Grafana: http://grafana.local (admin/admin123)" "$CYAN"
        log "   - Import SIEM dashboards from siem/dashboards/" "$CYAN"
        echo ""
        log "🔧 Next steps:" "$BLUE"
        log "   1. Run './test-siem.sh' to generate test events" "$CYAN"
        log "   2. Configure alerting rules if needed" "$CYAN"
        log "   3. Set up incident response procedures" "$CYAN"
        log "   4. Regular security monitoring and maintenance" "$CYAN"
    elif [[ "$FAILED_TESTS" -lt 3 ]]; then
        log "⚠️  Most tests passed with minor issues. Review failed tests above." "$YELLOW"
        log "🔧 Consider running './setup.sh' to fix any missing components." "$YELLOW"
    else
        log "❌ Multiple tests failed. SIEM setup needs attention." "$RED"
        log "🔧 Run './setup.sh' to deploy missing components." "$RED"
        log "📖 Check SIEM_DOCUMENTATION.md for troubleshooting guidance." "$RED"
    fi
    
    echo ""
    log "📋 For detailed troubleshooting, check:" "$BLUE"
    log "   - SIEM_DOCUMENTATION.md" "$CYAN"
    log "   - INCIDENT_RESPONSE_PLAYBOOK.md" "$CYAN"
    log "   - Component logs: microk8s kubectl logs -n <namespace> <pod>" "$CYAN"
}

# Check if running as root for some tests
if [[ $EUID -ne 0 ]]; then
    log "⚠️  Some tests require sudo privileges (system hardening checks)" "$YELLOW"
    log "Run with sudo for complete validation" "$YELLOW"
    echo ""
fi

# Run validation
main "$@"
