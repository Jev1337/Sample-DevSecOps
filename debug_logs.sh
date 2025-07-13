#!/bin/bash

# Debug script to check Loki logs and Grafana data
echo "=== Loki Debug Check ==="

# Check if Loki is running
echo "1. Checking Loki pod status..."
microk8s kubectl get pods -n monitoring | grep loki

# Check Loki logs
echo -e "\n2. Checking Loki logs..."
microk8s kubectl logs -n monitoring deployment/loki --tail=20

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

# Check Alloy logs
echo -e "\n7. Checking Alloy logs..."
microk8s kubectl logs -n monitoring deployment/alloy --tail=20

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

echo -e "\n=== Debug Check Complete ==="
