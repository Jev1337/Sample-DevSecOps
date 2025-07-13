#!/bin/bash

# Debug script to check Loki logs and Grafana data
echo "=== Loki Debug Check ==="

# Check if Loki is running
echo "1. Checking Loki pod status..."
microk8s kubectl get pods -n monitoring | grep loki

# Check Loki logs (try both deployment and statefulset)
echo -e "\n2. Checking Loki logs..."
if microk8s kubectl get deployment loki -n monitoring &>/dev/null; then
    microk8s kubectl logs -n monitoring deployment/loki --tail=20
elif microk8s kubectl get statefulset loki -n monitoring &>/dev/null; then
    microk8s kubectl logs -n monitoring statefulset/loki --tail=20
else
    echo "Loki deployment/statefulset not found, trying pod directly..."
    LOKI_POD=$(microk8s kubectl get pods -n monitoring -l app.kubernetes.io/name=loki -o jsonpath='{.items[0].metadata.name}')
    if [ ! -z "$LOKI_POD" ]; then
        microk8s kubectl logs -n monitoring pod/$LOKI_POD --tail=20
    else
        echo "No Loki pods found"
    fi
fi

# Check if Grafana is running
echo -e "\n3. Checking Grafana pod status..."
microk8s kubectl get pods -n monitoring | grep grafana

# Check Grafana logs
echo -e "\n4. Checking Grafana logs..."
microk8s kubectl logs -n monitoring deployment/grafana --tail=20

# Check if ConfigMaps exist for dashboards
echo -e "\n5. Checking dashboard ConfigMaps..."
microk8s kubectl get configmaps -n monitoring | grep dashboard

# Check Alloy status
echo -e "\n6. Checking Alloy pod status..."
microk8s kubectl get pods -n monitoring | grep alloy

# Check Alloy logs (try different resource types)
echo -e "\n7. Checking Alloy logs..."
if microk8s kubectl get deployment alloy -n monitoring &>/dev/null; then
    microk8s kubectl logs -n monitoring deployment/alloy --tail=20
elif microk8s kubectl get daemonset alloy -n monitoring &>/dev/null; then
    microk8s kubectl logs -n monitoring daemonset/alloy --tail=20
else
    echo "Alloy deployment/daemonset not found, trying pod directly..."
    ALLOY_POD=$(microk8s kubectl get pods -n monitoring -l app.kubernetes.io/name=alloy -o jsonpath='{.items[0].metadata.name}')
    if [ ! -z "$ALLOY_POD" ]; then
        echo "Checking Alloy pod logs:"
        microk8s kubectl logs -n monitoring pod/$ALLOY_POD --tail=20
        echo -e "\nChecking Alloy pod describe for issues:"
        microk8s kubectl describe pod $ALLOY_POD -n monitoring | tail -20
    else
        echo "No Alloy pods found"
    fi
fi

# Try to query Loki directly
echo -e "\n8. Testing Loki query API..."
LOKI_POD=$(microk8s kubectl get pods -n monitoring -l app.kubernetes.io/name=loki -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$LOKI_POD" ]; then
    echo "Found Loki pod: $LOKI_POD"
    microk8s kubectl port-forward -n monitoring pod/$LOKI_POD 3100:3100 &
    PF_PID=$!
    sleep 3
    
    echo "Querying Loki for labels..."
    curl -s "http://localhost:3100/loki/api/v1/labels" | jq .
    
    echo "Querying for any logs in last hour..."
    QUERY='%7Bjob%3D~%22.*%22%7D'  # URL encoded {job=~".*"}
    curl -s "http://localhost:3100/loki/api/v1/query_range?query=$QUERY&start=$(date -d '1 hour ago' +%s)000000000&end=$(date +%s)000000000" | jq .
    
    kill $PF_PID
fi

# Additional diagnostics for Alloy issues
echo -e "\n9. Detailed Alloy diagnostics..."
echo "Checking Alloy Helm release status:"
microk8s helm3 status alloy -n monitoring || echo "Alloy Helm release not found"

echo -e "\nChecking Alloy ConfigMap:"
microk8s kubectl get configmaps -n monitoring | grep alloy || echo "No Alloy ConfigMaps found"

echo -e "\nChecking Alloy ServiceAccount and RBAC:"
microk8s kubectl get serviceaccount alloy -n monitoring || echo "Alloy ServiceAccount not found"
microk8s kubectl get clusterrole alloy || echo "Alloy ClusterRole not found"
microk8s kubectl get clusterrolebinding alloy || echo "Alloy ClusterRoleBinding not found"

echo -e "\nChecking node resources:"
microk8s kubectl top nodes 2>/dev/null || echo "Metrics not available"

echo -e "\nChecking events related to Alloy:"
microk8s kubectl get events -n monitoring --field-selector involvedObject.kind=Pod | grep alloy || echo "No Alloy events found"

echo -e "\n=== Debug Check Complete ==="
