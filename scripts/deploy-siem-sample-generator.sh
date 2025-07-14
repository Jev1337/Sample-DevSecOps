#!/bin/bash

# SIEM Sample Data Generator Deployment Script
# This script deploys the sample data generator to provide realistic security logs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔒 SIEM Sample Data Generator Deployment"
echo "========================================="

# Create namespace if it doesn't exist
create_namespace() {
    echo "📦 Creating monitoring namespace..."
    microk8s kubectl create namespace monitoring --dry-run=client -o yaml | microk8s kubectl apply -f -
}

# Create ConfigMap with the sample data generator script
create_configmap() {
    echo "📝 Creating sample data generator ConfigMap..."
    microk8s kubectl create configmap siem-sample-data-generator \
        --from-file="$PROJECT_ROOT/scripts/generate-siem-sample-data.py" \
        -n monitoring \
        --dry-run=client -o yaml | microk8s kubectl apply -f -
}

# Create deployment for the sample data generator
create_deployment() {
    echo "🚀 Creating sample data generator deployment..."
    
    cat <<EOF | microk8s kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: siem-sample-data-generator
  namespace: monitoring
  labels:
    app: siem-sample-data-generator
spec:
  replicas: 1
  selector:
    matchLabels:
      app: siem-sample-data-generator
  template:
    metadata:
      labels:
        app: siem-sample-data-generator
    spec:
      containers:
      - name: generator
        image: python:3.9-slim
        env:
        - name: LOKI_URL
          value: "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
        command: ["/bin/bash"]
        args:
        - -c
        - |
          pip install requests
          python /scripts/generate-siem-sample-data.py
        volumeMounts:
        - name: script-volume
          mountPath: /scripts
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
      volumes:
      - name: script-volume
        configMap:
          name: siem-sample-data-generator
          defaultMode: 0755
      restartPolicy: Always
EOF
}

# Main execution
main() {
    echo "Starting SIEM sample data generator deployment..."
    
    create_namespace
    create_configmap
    create_deployment
    
    echo "⏳ Waiting for deployment to be ready..."
    microk8s kubectl wait --for=condition=Available deployment/siem-sample-data-generator -n monitoring --timeout=300s
    
    echo "✅ SIEM sample data generator deployed successfully!"
    echo ""
    echo "📊 The generator is now creating sample security events:"
    echo "   • SSH invalid user attempts"
    echo "   • Sudo usage logs" 
    echo "   • Package installation events"
    echo "   • Successful login attempts"
    echo ""
    echo "📈 Check your Grafana dashboard to see the generated data!"
    echo ""
    echo "To view logs:"
    echo "   microk8s kubectl logs -f deployment/siem-sample-data-generator -n monitoring"
    echo ""
    echo "To stop the generator:"
    echo "   microk8s kubectl delete deployment siem-sample-data-generator -n monitoring"
}

# Run main function
main
